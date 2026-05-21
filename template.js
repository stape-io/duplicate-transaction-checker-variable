const getClientName = require('getClientName');
const createRegex = require('createRegex');
const encodeUriComponent = require('encodeUriComponent');
const Firestore = require('Firestore');
const getEventData = require('getEventData');
const getRequestHeader = require('getRequestHeader');
const getType = require('getType');
const JSON = require('JSON');
const logToConsole = require('logToConsole');
const makeString = require('makeString');
const sendHttpRequest = require('sendHttpRequest');

/*==============================================================================
==============================================================================*/

let transactionId = data.transactionId || getEventData('transaction_id') || '';
transactionId = replaceAll(
  makeString(transactionId),
  data.stape ? '[^a-zA-Z0-9_$%@+=./-]' : '[^a-zA-Z0-9_$%@+=.-]',
  ''
);

if (!transactionId) {
  log({
    Name: 'DuplicateTransactionChecker',
    Type: 'Message',
    EventName: '🛑 [ERROR]',
    Message: 'Transaction ID is invalid'
  });
  return false;
}

let documentIdPrefix = 'duplicate-';
if (data.addClientNameToTransactionId) {
  let clientName = makeString(getClientName() || '');
  clientName = replaceAll(
    makeString(clientName),
    data.stape ? '[^a-zA-Z0-9_$%@+=./-]' : '[^a-zA-Z0-9_$%@+=.-]',
    ''
  );

  if (!clientName) {
    log({
      Name: 'DuplicateTransactionChecker',
      Type: 'Message',
      EventName: '🛑 [ERROR]',
      Message: 'Client Name ID is invalid'
    });
    return false;
  }

  documentIdPrefix += clientName + '_';
}

const documentId = documentIdPrefix + makeString(transactionId);

if (data.stape) {
  return stapeChecker(data, documentId, transactionId);
} else {
  return firestoreChecker(data, documentId, transactionId);
}

/*==============================================================================
  Vendor related functions
==============================================================================*/

function stapeChecker(data, documentId, transactionId) {
  const url = getStapeStoreDocumentUrl(data, documentId);

  return sendHttpRequest(url, { method: 'GET' })
    .then((response) => {
      const responseStatusCode = response.statusCode;

      if (responseStatusCode === 200) {
        return true;
      } else if (responseStatusCode === 404) {
        const body = { transaction_id: transactionId };

        return sendHttpRequest(
          url,
          { method: 'PUT', headers: { 'Content-Type': 'application/json' } },
          JSON.stringify(body)
        ).then((response) => {
          const responseStatusCode = response.statusCode;
          return false;
        });
      } else {
        return undefined;
      }
    })
    .catch((exception) => {
      return undefined;
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

function firestoreSuccessHandler(result) {
  if (result && result.id && !result.reason) return true;
  else return false;
}

function firestoreRejectionHandler(result, firestoreOptions, firestorePath, transactionId) {
  if (result.reason === 'not_found') {
    const inputData = { transaction_id: transactionId };
    return Firestore.write(firestorePath, inputData, firestoreOptions)
      .then(() => false)
      .catch((error) => {
        return undefined;
      });
  } else {
    return undefined;
  }
}

function firestoreChecker(data, documentId, transactionId) {
  const firestorePath = data.firebasePath + '/' + documentId;
  const firestoreOptions = { projectId: data.firebaseProjectId };

  return Firestore.read(firestorePath, firestoreOptions).then(
    (result) => firestoreSuccessHandler(result),
    (result) => firestoreRejectionHandler(result, firestoreOptions, firestorePath, transactionId)
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
  rawDataToLog.TraceId = getRequestHeader('trace-id');
  logToConsole(JSON.stringify(rawDataToLog));
}
