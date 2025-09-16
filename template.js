const getEventData = require('getEventData');
const makeString = require('makeString');
const JSON = require('JSON');
const Firestore = require('Firestore');
const sendHttpRequest = require('sendHttpRequest');
const encodeUriComponent = require('encodeUriComponent');
const logToConsole = require('logToConsole');
const getRequestHeader = require('getRequestHeader');
const getContainerVersion = require('getContainerVersion');
const getTimestampMillis = require('getTimestampMillis');
const BigQuery = require('BigQuery');

/*==============================================================================
==============================================================================*/

const traceId = getRequestHeader('trace-id');

const transaction_id = data.transactionId ? data.transactionId : getEventData('transaction_id');
const documentKey = generateDocumentKey();

if (!documentKey) {
  return false;
}

if (data.stape) {
  return stapeChecker();
}

return firestoreChecker();

/*==============================================================================
  Vendor related functions
==============================================================================*/

function stapeChecker() {
  let url = getStapeUrl();

  log({
    Name: 'DuplicateTransactionChecker',
    Type: 'Request',
    TraceId: traceId,
    EventName: 'DuplicateTransactionCheckerGet',
    RequestMethod: 'GET',
    RequestUrl: url
  });

  return sendHttpRequest(url, { method: 'GET' }).then(function (documents) {
    let responseStatusCode = documents.statusCode;
    if (responseStatusCode == 200) {
      log({
        Name: 'DuplicateTransactionChecker',
        Type: 'Response',
        TraceId: traceId,
        EventName: 'DuplicateTransactionCheckerGet',
        ResponseStatusCode: responseStatusCode,
        ResponseHeaders: {},
        ResponseBody: JSON.stringify(documents)
      });
      return true;
    } else if (responseStatusCode == 404) {
      sendHttpRequest(
        url,
        { method: 'PUT', headers: { 'Content-Type': 'application/json' } },
        JSON.stringify({ transaction_id: transaction_id })
      ).then(function (response) {
        log({
          Name: 'DuplicateTransactionChecker',
          Type: 'Response',
          TraceId: traceId,
          EventName: 'DuplicateTransactionCheckerWrite',
          ResponseStatusCode: responseStatusCode,
          ResponseHeaders: {},
          ResponseBody: JSON.stringify(response)
        });
      });
      return false;
    } else {
      log({
        Name: 'DuplicateTransactionChecker',
        Type: 'Message',
        TraceId: traceId,
        EventName: 'Error',
        ResponseStatusCode: responseStatusCode,
        ResponseHeaders: {},
        ResponseBody: JSON.stringify(documents),
        Message: 'Error during request to Stape store'
      });
      return undefined;
    }
  });
}

function firestoreChecker() {
  const projectId = data.firebaseProjectId;
  const documentPath = data.firebasePath + '/' + documentKey;

  return Firestore.read(documentPath, { projectId: projectId })
    .then(function (result) {
      if (result.exists) {
        return true;
      } else {
        return Firestore.write(documentPath, {
          projectId: projectId,
          data: { transaction_id: documentKey }
        }).then(function () {
          return false;
        });
      }
    })
    .catch(function (error) {
      log({
        Name: 'DuplicateTransactionChecker',
        Type: 'Message',
        TraceId: traceId,
        EventName: 'Error',
        Message: 'Error writing to Firestore'
      });

      return undefined;
    });
}

function getStoreUrl() {
  const containerIdentifier = getRequestHeader('x-gtm-identifier');
  const defaultDomain = getRequestHeader('x-gtm-default-domain');
  const containerApiKey = getRequestHeader('x-gtm-api-key');

  return (
    'https://' +
    enc(containerIdentifier) +
    '.' +
    enc(defaultDomain) +
    '/stape-api/' +
    enc(containerApiKey) +
    '/v1/store'
  );
}

function getStapeUrl() {
  return getStoreUrl() + '/' + enc(documentKey);
}

function generateDocumentKey() {
  if (!transaction_id) {
    log({
      Name: 'DuplicateTransactionChecker',
      Type: 'Message',
      TraceId: traceId,
      EventName: 'Error',
      Message: 'Transaction id is empty'
    });
    return false;
  }

  return 'duplicate-' + makeString(transaction_id);
}

/*==============================================================================
  Helpers
==============================================================================*/

function enc(data) {
  return encodeUriComponent(makeString(data || ''));
}

function log(rawDataToLog) {
  const logDestinationsHandlers = {};
  if (determinateIsLoggingEnabled()) logDestinationsHandlers.console = logConsole;
  if (determinateIsLoggingEnabledForBigQuery()) logDestinationsHandlers.bigQuery = logToBigQuery;

  const keyMappings = {
    // No transformation for Console is needed.
    bigQuery: {
      Name: 'tag_name',
      Type: 'type',
      TraceId: 'trace_id',
      EventName: 'event_name',
      RequestMethod: 'request_method',
      RequestUrl: 'request_url',
      RequestBody: 'request_body',
      ResponseStatusCode: 'response_status_code',
      ResponseHeaders: 'response_headers',
      ResponseBody: 'response_body'
    }
  };

  for (const logDestination in logDestinationsHandlers) {
    const handler = logDestinationsHandlers[logDestination];
    if (!handler) continue;

    const mapping = keyMappings[logDestination];
    const dataToLog = mapping ? {} : rawDataToLog;

    if (mapping) {
      for (const key in rawDataToLog) {
        const mappedKey = mapping[key] || key;
        dataToLog[mappedKey] = rawDataToLog[key];
      }
    }

    handler(dataToLog);
  }
}

function logConsole(dataToLog) {
  logToConsole(JSON.stringify(dataToLog));
}

function logToBigQuery(dataToLog) {
  const connectionInfo = {
    projectId: data.logBigQueryProjectId,
    datasetId: data.logBigQueryDatasetId,
    tableId: data.logBigQueryTableId
  };

  dataToLog.timestamp = getTimestampMillis();

  ['request_body', 'response_headers', 'response_body'].forEach((p) => {
    dataToLog[p] = JSON.stringify(dataToLog[p]);
  });

  BigQuery.insert(connectionInfo, [dataToLog], { ignoreUnknownValues: true });
}

function determinateIsLoggingEnabled() {
  const containerVersion = getContainerVersion();
  const isDebug = !!(
    containerVersion &&
    (containerVersion.debugMode || containerVersion.previewMode)
  );

  if (!data.logType) {
    return isDebug;
  }

  if (data.logType === 'no') {
    return false;
  }

  if (data.logType === 'debug') {
    return isDebug;
  }

  return data.logType === 'always';
}

function determinateIsLoggingEnabledForBigQuery() {
  if (data.bigQueryLogType === 'no') return false;
  return data.bigQueryLogType === 'always';
}
