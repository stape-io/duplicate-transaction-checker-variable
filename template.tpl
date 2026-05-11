___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Duplicate Transaction Checker",
  "categories": [
    "UTILITY",
    "DATA_WAREHOUSING"
  ],
  "description": "Verify if the current transaction ID has been previously recorded. Utilize a database to store and manage transaction IDs.",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "GROUP",
    "name": "configGroup",
    "subParams": [
      {
        "type": "SELECT",
        "name": "transactionId",
        "displayName": "Transaction ID",
        "macrosInSelect": true,
        "selectItems": [
          {
            "value": "",
            "displayValue": "Event Data -\u003e transaction_id"
          }
        ],
        "simpleValueType": true,
        "help": "Select the variable containing your Transaction ID. If left blank, the system will automatically look for the \"transaction_id\" key within the Event Data.\n\u003cbr/\u003e\u003cbr/\u003e\n\u003cb\u003eNote:\u003c/b\u003e Any characters in the Transaction ID that do not match the permitted set (a-zA-Z0-9_$%@+\u003d./-) will be removed to comply with Stape Store  and Firestore requirements."
      },
      {
        "type": "CHECKBOX",
        "name": "stape",
        "checkboxText": "I use Stape.io",
        "simpleValueType": true,
        "help": "In case you don\u0027t use Stape.io you need to use Firebase for storing transactions.",
        "defaultValue": true
      },
      {
        "type": "CHECKBOX",
        "name": "addClientNameToTransactionId",
        "checkboxText": "Use Client Name as prefix of Transaction ID",
        "simpleValueType": true,
        "help": "Enable this option to add the name of the Client that claimed the request as a prefix to the Transaction ID registered in the database.\n\u003c/br\u003e\u003c/br\u003e\nUse this option in case you have multiple Clients receiving the same Transaction ID from different requests (e.g. GA4 Client and Data Client) and you want to be able to run logic in sGTM without considering the transaction to be duplicated for different Clients. \n\u003c/br\u003e\u003c/br\u003e\nUse wisely since this will create a single Transaction ID for each Client handling the conversion.",
        "defaultValue": false
      }
    ]
  },
  {
    "displayName": "Firebase Settings",
    "name": "firebaseGroup",
    "groupStyle": "ZIPPY_CLOSED",
    "type": "GROUP",
    "subParams": [
      {
        "type": "TEXT",
        "name": "firebaseProjectId",
        "displayName": "Firebase Project ID",
        "simpleValueType": true,
        "help": "Optional. \n\u003cbr/\u003e\u003cbr/\u003e\nThe Google Cloud Platform project ID. \n\u003cbr/\u003e\nIf omitted, the Project ID is retrieved from the environment variable \u003ci\u003eGOOGLE_CLOUD_PROJECT\u003c/i\u003e as long as the \u003ci\u003eaccess_firestore\u003c/i\u003e permission setting for the project ID is set to * or \u003ci\u003eGOOGLE_CLOUD_PROJECT\u003c/i\u003e.\n\u003cbr/\u003e\nIf the server container is running on Google Cloud, \u003ci\u003eGOOGLE_CLOUD_PROJECT\u003c/i\u003e will already be set to the Google Cloud project\u0027s ID."
      },
      {
        "type": "TEXT",
        "name": "firebasePath",
        "displayName": "Firebase Collection",
        "simpleValueType": true,
        "help": "The path to the collection in Firebase where the data will be stored.\n\u003cbr/\u003e\nEach Transaction ID will be stored in a document named: \"duplicate-{Transaction ID}\".\n\u003cbr/\u003e\n\u003cbr/\u003e\nThe Firebase integration supports only Firestore in \u003cb\u003eNative mode\u003c/b\u003e, not Firestore in Datastore mode. \n\u003cbr/\u003e\nAlso, it only supports using the \u003cb\u003e(default) database\u003c/b\u003e.",
        "valueValidators": [
          {
            "type": "NON_EMPTY"
          }
        ],
        "defaultValue": "stape"
      }
    ],
    "enablingConditions": [
      {
        "paramName": "stape",
        "paramValue": false,
        "type": "EQUALS"
      }
    ]
  },
  {
    "type": "GROUP",
    "name": "stapeStoreSettingsGroup",
    "displayName": "Stape Store Settings",
    "groupStyle": "ZIPPY_OPEN_ON_PARAM",
    "subParams": [
      {
        "type": "TEXT",
        "name": "stapeStoreCollectionName",
        "displayName": "Stape Store Collection Name",
        "simpleValueType": true,
        "help": "The name of the collection on the Stape Store that contains (or will contain) the document with the data.\n\u003cbr/\u003e\u003cbr/\u003e\nIf not set, the \u003ci\u003edefault\u003c/i\u003e Collection Name will be used.",
        "defaultValue": "default"
      },
      {
        "type": "SELECT",
        "name": "useDifferentStapeStore",
        "displayName": "Use the Stape Store database of a different container",
        "macrosInSelect": true,
        "selectItems": [
          {
            "value": true,
            "displayValue": "true"
          },
          {
            "value": false,
            "displayValue": "false"
          }
        ],
        "simpleValueType": true,
        "subParams": [
          {
            "type": "TEXT",
            "name": "stapeStoreContainerApiKey",
            "displayName": "Stape Store Container API Key",
            "simpleValueType": true,
            "valueHint": "euk:kzlfoobar:55ec021d429be49e64e691429cf0f27440a1b789kzlfoobar",
            "help": "If you want to interact with the Stape Store of a different container hosted on Stape, specify the \u003cb\u003eContainer API Key\u003c/b\u003e of this container.\n\u003cbr/\u003e\u003cbr/\u003e\nTo find the \u003cb\u003eContainer API Key\u003c/b\u003e, go to the \u003ca href\u003d\"https://app.eu.stape.dev/container\"\u003eStape Admin panel\u003c/a\u003e, select the sGTM container which the Stape Store you want to interact with, go to the \u003ci\u003eSettings\u003c/i\u003e tab and scroll down to the \u003ci\u003eContainer settings\u003c/i\u003e section.",
            "enablingConditions": [
              {
                "paramName": "useDifferentStapeStore",
                "paramValue": false,
                "type": "NOT_EQUALS"
              }
            ],
            "valueValidators": [
              {
                "type": "NON_EMPTY"
              }
            ]
          }
        ],
        "defaultValue": false
      }
    ],
    "enablingConditions": [
      {
        "paramName": "stape",
        "paramValue": true,
        "type": "EQUALS"
      }
    ]
  },
  {
    "displayName": "Logs Settings",
    "name": "logsGroup",
    "groupStyle": "ZIPPY_CLOSED",
    "type": "GROUP",
    "subParams": [
      {
        "type": "RADIO",
        "name": "logType",
        "radioItems": [
          {
            "value": "no",
            "displayValue": "Do not log"
          },
          {
            "value": "debug",
            "displayValue": "Log to console during debug and preview"
          },
          {
            "value": "always",
            "displayValue": "Always log to console"
          }
        ],
        "simpleValueType": true,
        "defaultValue": "debug"
      }
    ]
  },
  {
    "displayName": "BigQuery Logs Settings",
    "name": "bigQueryLogsGroup",
    "groupStyle": "ZIPPY_CLOSED",
    "type": "GROUP",
    "subParams": [
      {
        "type": "RADIO",
        "name": "bigQueryLogType",
        "radioItems": [
          {
            "value": "no",
            "displayValue": "Do not log to BigQuery"
          },
          {
            "value": "always",
            "displayValue": "Log to BigQuery"
          }
        ],
        "simpleValueType": true,
        "defaultValue": "no"
      },
      {
        "type": "GROUP",
        "name": "logsBigQueryConfigGroup",
        "groupStyle": "NO_ZIPPY",
        "subParams": [
          {
            "type": "TEXT",
            "name": "logBigQueryProjectId",
            "displayName": "BigQuery Project ID",
            "simpleValueType": true,
            "help": "Optional.  \u003cbr/\u003e\u003cbr/\u003e  If omitted, it will be retrieved from the environment variable \u003cI\u003eGOOGLE_CLOUD_PROJECT\u003c/i\u003e where the server container is running. If the server container is running on Google Cloud, \u003cI\u003eGOOGLE_CLOUD_PROJECT\u003c/i\u003e will already be set to the Google Cloud project\u0027s ID."
          },
          {
            "type": "TEXT",
            "name": "logBigQueryDatasetId",
            "displayName": "BigQuery Dataset ID",
            "simpleValueType": true,
            "valueValidators": [
              {
                "type": "NON_EMPTY"
              }
            ]
          },
          {
            "type": "TEXT",
            "name": "logBigQueryTableId",
            "displayName": "BigQuery Table ID",
            "simpleValueType": true,
            "valueValidators": [
              {
                "type": "NON_EMPTY"
              }
            ]
          }
        ],
        "enablingConditions": [
          {
            "paramName": "bigQueryLogType",
            "paramValue": "always",
            "type": "EQUALS"
          }
        ]
      }
    ]
  }
]


___SANDBOXED_JS_FOR_SERVER___

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
    EventName: 'Error',
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
      EventName: 'Error',
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

  log({
    Name: 'DuplicateTransactionChecker',
    Type: 'Request',
    EventName: 'DuplicateTransactionCheckerGet',
    RequestMethod: 'GET',
    RequestUrl: url
  });

  return sendHttpRequest(url, { method: 'GET' })
    .then((response) => {
      const responseStatusCode = response.statusCode;

      log({
        Name: 'DuplicateTransactionChecker',
        Type: 'Response',
        EventName: 'DuplicateTransactionCheckerGet',
        ResponseStatusCode: responseStatusCode,
        ResponseHeaders: {},
        ResponseBody: response.body
      });

      if (responseStatusCode === 200) {
        return true;
      } else if (responseStatusCode === 404) {
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
    })
    .catch((exception) => {
      log({
        Name: 'DuplicateTransactionChecker',
        Type: 'Message',
        EventName: 'Error',
        Message: 'Error during request to Stape Store',
        Reason: JSON.stringify(exception)
      });
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
        log({
          Name: 'DuplicateTransactionChecker',
          Type: 'Message',
          EventName: 'Error',
          Message: 'Error writing to Firestore',
          Reason: JSON.stringify(error)
        });
        return undefined;
      });
  } else {
    log({
      Name: 'DuplicateTransactionChecker',
      Type: 'Message',
      EventName: 'Error',
      Message: 'Error reading from Firestore',
      Reason: JSON.stringify(result)
    });
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


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "access_firestore",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedOptions",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "projectId"
                  },
                  {
                    "type": 1,
                    "string": "path"
                  },
                  {
                    "type": 1,
                    "string": "operation"
                  },
                  {
                    "type": 1,
                    "string": "databaseId"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "read_write"
                  },
                  {
                    "type": 1,
                    "string": "(default)"
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "all"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_request",
        "versionId": "1"
      },
      "param": [
        {
          "key": "headerWhitelist",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "x-gtm-identifier"
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "x-gtm-default-domain"
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "x-gtm-api-key"
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "trace-id"
                  }
                ]
              }
            ]
          }
        },
        {
          "key": "headersAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "requestAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "headerAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "queryParameterAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_container_data",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_event_data",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keyPatterns",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "transaction_id"
              }
            ]
          }
        },
        {
          "key": "eventDataAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "send_http",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_bigquery",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedTables",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "projectId"
                  },
                  {
                    "type": 1,
                    "string": "datasetId"
                  },
                  {
                    "type": 1,
                    "string": "tableId"
                  },
                  {
                    "type": 1,
                    "string": "operation"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: Stape Checker - New Transaction (With Prefix)
  code: "const mockData = {\n  stape: true,\n  addClientNameToTransactionId: true,\n\
    \  transactionId: 'TID-12345',\n  stapeStoreCollectionName: 'default'\n};\n\n\
    mock('getClientName', () => 'Custom Data Client'); // Has spaces!\nmock('getEventData',\
    \ () => undefined);\n\nmock('sendHttpRequest', (url, options, body) => {\n  if\
    \ (options.method === 'GET') {\n    assertThat(url).contains('duplicate-CustomDataClient_TID-12345');\n\
    \    return Promise.create((resolve) => resolve({ statusCode: 404, body: '' }));\n\
    \  } \n  \n  if (options.method === 'PUT') {\n    const parsedBody = JSON.parse(body);\n\
    \    assertThat(parsedBody.transaction_id).isEqualTo('TID-12345');\n    return\
    \ Promise.create((resolve) => resolve({ statusCode: 200, body: '' }));\n  }\n\
    });\n\nrunCode(mockData).then((result) => {\n  assertThat(result).isFalse();\n\
    });"
- name: Stape Checker - Duplicate Transaction Found (No Prefix)
  code: |-
    const mockData = {
      stape: true,
      addPrefix: false,
      transactionId: 'TID-123456',
      stapeStoreCollectionName: 'default'
    };

    mock('getClientName', () => 'Client1');
    mock('getEventData', () => undefined);

    mock('sendHttpRequest', (url, options) => {
      if (options.method === 'GET') {
        assertThat(url).contains('duplicate-TID-123456');
        return Promise.create((resolve) => resolve({ statusCode: 200, body: '' }));
      }
    });

    runCode(mockData).then((result) => {
      assertThat(result).isTrue();
    });
- name: Firestore Checker - New Transaction (With Prefix)
  code: |-
    const mockData = {
      stape: false,
      addClientNameToTransactionId: true,
      transactionId: 'TID-12345-FS',
      firebaseProjectId: 'my-project',
      firebasePath: 'firestore_path'
    };

    mock('getClientName', () => 'Store Client');
    mock('getEventData', () => undefined);

    mockObject('Firestore', {
      read: (path) => {
        assertThat(path).isEqualTo('firestore_path/duplicate-StoreClient_TID-12345-FS');
        return Promise.create((resolve, reject) => reject({ reason: 'not_found' }));
      },
      write: (path, data) => {
        assertThat(data.transaction_id).isEqualTo('TID-12345-FS');
        return Promise.create((resolve) => resolve({ id: 'success_id' }));
      }
    });

    runCode(mockData).then((result) => {
      assertThat(result).isFalse();
    });
- name: Firestore Checker - Duplicate Transaction (No Prefix)
  code: |-
    const mockData = {
      stape: false,
      addPrefix: false,
      transactionId: 'TID-12345-FS',
      firebaseProjectId: 'my-project',
      firebasePath: 'firestore_path'
    };

    mock('getClientName', () => 'Store Client');
    mock('getEventData', () => undefined);

    mockObject('Firestore', {
      read: (path) => {
        assertThat(path).isEqualTo('firestore_path/duplicate-TID-12345-FS');
        return Promise.create((resolve, reject) => resolve({ id: 'FOUND' }));
      }
    });

    runCode(mockData).then((result) => {
      assertThat(result).isTrue();
    });
- name: Empty Transaction ID Guard Clause
  code: "const mockData = {\n  stape: true,\n  addPrefix: true, \n  transactionId:\
    \ ''\n};\n\nmock('getClientName', () => 'Client');\nmock('getEventData', () =>\
    \ undefined);\n\nconst result = runCode(mockData);\n\nassertThat(result).isFalse();\n\
    assertApi('sendHttpRequest').wasNotCalled();"
setup: |-
  const Promise = require('Promise');
  const JSON = require('JSON');

  mock('getRequestHeader', () => 'test-header');
  mock('getContainerVersion', () => ({ debugMode: true }));
  mock('getTimestampMillis', () => 1000000000000);
  mock('BigQuery', { insert: () => {} });
  mock('sendHttpRequest', (url, options, body) => {
   return Promise.create((resolve) => resolve({ statusCode: 200, headers: {}, body: '' }));
  });


___NOTES___

2026-05-11 - Change Notes:
  - Add prefix checkbox, fix Firestore code and add tests.

Created on 7/23/2024, 1:55:47 PM

