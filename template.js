/// <reference path="./server-gtm-sandboxed-apis.d.ts" />

const BigQuery = require('BigQuery');
const getClientName = require('getClientName');
const createRegex = require('createRegex');
const encodeUriComponent = require('encodeUriComponent');
const Firestore = require('Firestore');
const getContainerVersion = require('getContainerVersion');
const getEventData = require('getEventData');
const getRequestHeader = require('getRequestHeader');
const getTimestampMillis = require('getTimestampMillis');
const getType = require('getType');
const JSON = require('JSON');
const logToConsole = require('logToConsole');
const makeString = require('makeString');
const sendHttpRequest = require('sendHttpRequest');

/*==============================================================================
==============================================================================*/

const clientName = getClientName();
let transactionId = data.transactionId || getEventData('transaction_id') || '';
const transactionPrefix = data.addPrefix ? makeString(clientName) + '_' : '';
const projectId = data.firebaseProjectId;

if (!transactionId) {
  log({
    Name: 'DuplicateTransactionChecker',
    Type: 'Message',
    EventName: 'Error',
    Message: 'Transaction id is empty'
  });
  return undefined;
}

transactionId = transactionPrefix + transactionId;
transactionId = replaceAll(makeString(transactionId), '[^a-zA-Z0-9_$%@+=./-]', '');

const documentId = 'duplicate-' + makeString(transactionId);
const firestorePathArgument = data.firebasePath + '/' + documentId;

if (data.stape) {
  return stapeChecker(data, documentId, transactionId);
} else {
  return firestoreChecker(firestorePathArgument);
}

/*==============================================================================
  Vendor related functions
==============================================================================*/

function stapeChecker(data, documentId, transactionId) {
  const url = getStapeStoreDocumentUrl(data, documentId);

  log({
    Name: 'DuplicateTransactionChecker',
    Type: 'Request',
    EventName: 'DuplicateTransactionCheckerGet',
    RequestMethod: 'GET',
    RequestUrl: url
  });

  return sendHttpRequest(url, { method: 'GET' }).then((response) => {
    const responseStatusCode = response.statusCode;

    log({
      Name: 'DuplicateTransactionChecker',
      Type: 'Response',
      EventName: 'DuplicateTransactionCheckerGet',
      ResponseStatusCode: responseStatusCode,
      ResponseHeaders: {},
      ResponseBody: response.body
    });

    if (responseStatusCode == 200) {
      return true;
    } else if (responseStatusCode == 404) {
      const body = { transaction_id: transactionId };

      log({
        Name: 'DuplicateTransactionChecker',
        Type: 'Request',
        EventName: 'DuplicateTransactionCheckerWrite',
        RequestMethod: 'PUT',
        RequestUrl: url,
        RequestBody: body
      });

      return sendHttpRequest(
        url,
        { method: 'PUT', headers: { 'Content-Type': 'application/json' } },
        JSON.stringify(body)
      ).then((response) => {
        const responseStatusCode = response.statusCode;

        log({
          Name: 'DuplicateTransactionChecker',
          Type: 'Response',
          EventName: 'DuplicateTransactionCheckerWrite',
          ResponseStatusCode: responseStatusCode,
          ResponseHeaders: {},
          ResponseBody: response.body
        });

        return false;
      });
    } else {
      log({
        Name: 'DuplicateTransactionChecker',
        Type: 'Message',
        EventName: 'Error',
        ResponseStatusCode: responseStatusCode,
        ResponseHeaders: {},
        ResponseBody: response.body,
        Message: 'Error during request to Stape Store'
      });

      return undefined;
    }
  });
}

function getStapeStoreBaseUrl(data) {
  let containerIdentifier;
  let defaultDomain;
  let containerApiKey;
  const collectionPath =
    'collections/' + enc(data.stapeStoreCollectionName || 'default') + '/documents';

  const shouldUseDifferentStore =
    isUIFieldTrue(data.useDifferentStapeStore) &&
    getType(data.stapeStoreContainerApiKey) === 'string';
  if (shouldUseDifferentStore) {
    const containerApiKeyParts = data.stapeStoreContainerApiKey.split(':');

    const containerLocation = containerApiKeyParts[0];
    const containerRegion = containerApiKeyParts[3] || 'io';
    containerIdentifier = containerApiKeyParts[1];
    defaultDomain = containerLocation + '.stape.' + containerRegion;
    containerApiKey = containerApiKeyParts[2];
  } else {
    containerIdentifier = getRequestHeader('x-gtm-identifier');
    defaultDomain = getRequestHeader('x-gtm-default-domain');
    containerApiKey = getRequestHeader('x-gtm-api-key');
  }

  return (
    'https://' +
    enc(containerIdentifier) +
    '.' +
    enc(defaultDomain) +
    '/stape-api/' +
    enc(containerApiKey) +
    '/v2/store/' +
    collectionPath
  );
}

function getStapeStoreDocumentUrl(data, documentId) {
  const storeBaseUrl = getStapeStoreBaseUrl(data);
  return storeBaseUrl + '/' + enc(documentId);
}

function firestoreResponseHandler(result) {
  if (result.id && result.reason !== 'not_found' && result.reason !== 'invalid_argument')
    return true;
  else return false;
}

function firestoreRejectionHandler(reject) {
  const firestoreOptions = {
    projectId: projectId,
    data: { transaction_id: transactionId }
  };

  if (reject.reason === 'not_found') {
    return Firestore.write(firestorePathArgument, firestoreOptions)
      .then(() => false)
      .catch((error) => {
        log({
          Name: 'DuplicateTransactionChecker',
          Type: 'Message',
          EventName: 'Error',
          Message: 'Error reading or writing to Firestore',
          Reason: error.reason,
          Body: JSON.stringify(error)
        });
      });
  }
  return undefined;
}

function firestoreChecker(firestorePathArgument) {
  return Firestore.read(firestorePathArgument, { projectId: projectId }).then(
    firestoreResponseHandler,
    firestoreRejectionHandler
  );
}

/*==============================================================================
  Helpers
==============================================================================*/

function replaceAll(str, find, replace) {
  if (getType(str) !== 'string') return str;
  const regex = createRegex(find, 'g');
  return str.replace(regex, replace);
}

function isUIFieldTrue(field) {
  return [true, 'true', 1, '1'].indexOf(field) !== -1;
}

function enc(data) {
  if (['null', 'undefined'].indexOf(getType(data)) !== -1) data = '';
  return encodeUriComponent(makeString(data));
}

function log(rawDataToLog) {
  const logDestinationsHandlers = {};
  if (determinateIsLoggingEnabled()) logDestinationsHandlers.console = logConsole;
  if (determinateIsLoggingEnabledForBigQuery()) logDestinationsHandlers.bigQuery = logToBigQuery;

  rawDataToLog.TraceId = getRequestHeader('trace-id');

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
