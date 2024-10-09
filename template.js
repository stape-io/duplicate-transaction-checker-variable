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
const transaction_id = data.transactionId ? data.transactionId : getEventData('transaction_id');
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
    .then(function(documents) {
      let responseStatusCode = documents.statusCode;
      if(responseStatusCode == 200) {
      if (isLoggingEnabled) {
        logToConsole(
          JSON.stringify({
            Name: 'DuplicateTransactionChecker',
              Type: 'Response',
            TraceId: traceId,
              EventName: 'DuplicateTransactionCheckerGet',
              ResponseStatusCode: responseStatusCode,
              ResponseHeaders: {},
              ResponseBody: JSON.stringify(documents),
          }));
      }
        return true;
      } else if (responseStatusCode == 404) {
        sendHttpRequest(url, {method: 'PUT', headers: { 'Content-Type': 'application/json' }}, JSON.stringify({'transaction_id': transaction_id})
          ).then(function(response) {
          if (isLoggingEnabled) {
            logToConsole(
              JSON.stringify({
                Name: 'DuplicateTransactionChecker',
                Type: 'Response',
                TraceId: traceId,
                EventName: 'DuplicateTransactionCheckerWrite',
                  ResponseStatusCode: responseStatusCode,
                ResponseHeaders: {},
                  ResponseBody: JSON.stringify(response),
              }));
          }
          }
        );
          return false;
        
      } else {
          if (isLoggingEnabled) {
            logToConsole(
              JSON.stringify({
                Name: 'DuplicateTransactionChecker',
              Type: 'Message',
                TraceId: traceId,
              EventName: 'Error',
              ResponseStatusCode: responseStatusCode,
                ResponseHeaders: {},
              ResponseBody: JSON.stringify(documents),
              Message: 'Error during request to Stape store'
          }
          ));
        }
          return undefined;
      }
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
            Type: 'Message',
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

  if (!transaction_id) {
    if (isLoggingEnabled) {
      logToConsole(
        JSON.stringify({
          Name: 'DuplicateTransactionChecker',
          Type: 'Message',
          TraceId: traceId,
          EventName: 'Error',
          Message: 'Transaction id is empty',
        })
      );
    }
    return false;
  }

  return 'duplicate-' + makeString(transaction_id);
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