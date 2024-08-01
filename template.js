const getEventData = require('getEventData');
const makeString = require('makeString');
const JSON = require('JSON');
const Firestore = require('Firestore');
const sendHttpRequest = require('sendHttpRequest');
const encodeUriComponent = require('encodeUriComponent');
const logToConsole = require('logToConsole');
const getRequestHeader = require('getRequestHeader');
const getContainerVersion = require('getContainerVersion');

const isLoggingEnabled = determinateIsLoggingEnabled();
const traceId = isLoggingEnabled ? getRequestHeader('trace-id') : undefined;

const documentKey = generateDocumentKey();

if (!documentKey) {
  return false;
}

if (data.stape) {
  return stapeChecker();
}

return firestoreChecker();


function stapeChecker() {
  let url = getStapeUrl();

  if (isLoggingEnabled) {
    logToConsole(
      JSON.stringify({
        Name: 'DuplicateTransactionChecker',
        Type: 'Request',
        TraceId: traceId,
        EventName: 'DuplicateTransactionCheckerGet',
        RequestMethod: 'GET',
        RequestUrl: url,
      })
    );
  }

  return sendHttpRequest(url, {method: 'GET'})
    .then((documents) => {
      let body = documents.body;

      return true;
    }, () => {
      const objectToStore = {u: true};

      if (isLoggingEnabled) {
        logToConsole(
          JSON.stringify({
            Name: 'DuplicateTransactionChecker',
            Type: 'Request',
            TraceId: traceId,
            EventName: 'DuplicateTransactionCheckerWrite',
            RequestMethod: 'POST',
            RequestUrl: url,
            RequestBody: objectToStore,
          })
        );
      }

      return sendHttpRequest(url, {method: 'PUT', headers: { 'Content-Type': 'application/json' }}, JSON.stringify(objectToStore))
        .then(() => {
          if (isLoggingEnabled) {
            logToConsole(
              JSON.stringify({
                Name: 'DuplicateTransactionChecker',
                Type: 'Response',
                TraceId: traceId,
                EventName: 'DuplicateTransactionCheckerWrite',
                ResponseStatusCode: 200,
                ResponseHeaders: {},
                ResponseBody: {},
              })
            );
          }

          return false;
        }, function () {
          if (isLoggingEnabled) {
            logToConsole(
              JSON.stringify({
                Name: 'DuplicateTransactionChecker',
                Type: 'Response',
                TraceId: traceId,
                EventName: 'DuplicateTransactionCheckerWrite',
                ResponseStatusCode: 500,
                ResponseHeaders: {},
                ResponseBody: {},
              })
            );
          }

          return undefined;
        });
    });
}

function firestoreChecker() {
  const projectId = data.firebaseProjectId;
  const documentPath = data.firebasePath + '/' + documentKey;

  return Firestore.read(documentPath, { projectId: projectId })
    .then(function(result) {
      if (result.exists) {
        return true;
      } else {
        return Firestore.write(documentPath, {
          projectId: projectId,
          data: { transaction_id: documentKey }
        }).then(function() {
          return false;
        });
      }
    })
    .catch(function(error) {
      if (isLoggingEnabled) {
        logToConsole(
          JSON.stringify({
            Name: 'DuplicateTransactionChecker',
            Type: 'Other',
            TraceId: traceId,
            EventName: 'Error',
            Message: 'Error writing to Firestore',
          })
        );
      }

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
  let transactionId = data.transaction_id;

  if (transactionId === 'transaction_id') {
    transactionId = getEventData('transaction_id');
  }

  if (!transactionId) {
    if (isLoggingEnabled) {
      logToConsole(
        JSON.stringify({
          Name: 'DuplicateTransactionChecker',
          Type: 'Other',
          TraceId: traceId,
          EventName: 'Error',
          Message: 'Transaction id is empty',
        })
      );
    }

    return false;
  }

  return 'duplicate-' + makeString(transactionId);
}

function determinateIsLoggingEnabled() {
  const containerVersion = getContainerVersion();
  const isDebug = !!(containerVersion && (containerVersion.debugMode || containerVersion.previewMode));

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

function enc(data) {
  data = data || '';
  return encodeUriComponent(data);
}

