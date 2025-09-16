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
  "description": "Verify if the current transaction ID has been previously recorded. Utilize a database to store and manage transaction IDs.",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
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
    "help": "Insert transaction ID variable or it will look for \"transaction_id\" in event data."
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
    "displayName": "Firebase Settings",
    "name": "firebaseGroup",
    "groupStyle": "ZIPPY_CLOSED",
    "type": "GROUP",
    "subParams": [
      {
        "type": "TEXT",
        "name": "firebaseProjectId",
        "displayName": "Firebase Project ID",
        "simpleValueType": true
      },
      {
        "type": "TEXT",
        "name": "firebasePath",
        "displayName": "Firebase Path",
        "simpleValueType": true,
        "help": "The variable uses Firebase to store data. You can choose any key for a document that will store the data values.",
        "valueValidators": [
          {
            "type": "NON_EMPTY"
          }
        ],
        "defaultValue": "stape/duplicate"
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
        "help": "The name of the collection on the Stape Store that contains (or will contain) the document with the data.\n\u003cbr/\u003e\u003cbr/\u003e\nIf not set, the \u003ci\u003edefault\u003c/i\u003e Collection Name will be used."
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

const transactionId = data.transactionId ? data.transactionId : getEventData('transaction_id');
const documentId = generateDocumentId(transactionId);

if (!documentId) {
  return false;
}

if (data.stape) {
  return stapeChecker(data, documentId, transactionId);
}

return firestoreChecker(data, documentId);

/*==============================================================================
  Vendor related functions
==============================================================================*/

function generateDocumentId(transactionId) {
  if (!transactionId) {
    log({
      Name: 'DuplicateTransactionChecker',
      Type: 'Message',
      TraceId: traceId,
      EventName: 'Error',
      Message: 'Transaction id is empty'
    });

    return false;
  }

  return 'duplicate-' + makeString(transactionId);
}

function stapeChecker(data, documentId, transactionId) {
  const url = getStapeStoreDocumentUrl(data, documentId);

  log({
    Name: 'DuplicateTransactionChecker',
    Type: 'Request',
    TraceId: traceId,
    EventName: 'DuplicateTransactionCheckerGet',
    RequestMethod: 'GET',
    RequestUrl: url
  });

  return sendHttpRequest(url, { method: 'GET' }).then(function (response) {
    const responseStatusCode = response.statusCode;

    log({
      Name: 'DuplicateTransactionChecker',
      Type: 'Response',
      TraceId: traceId,
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
        TraceId: traceId,
        EventName: 'DuplicateTransactionCheckerWrite',
        RequestMethod: 'PUT',
        RequestUrl: url,
        RequestBody: body
      });

      sendHttpRequest(
        url,
        { method: 'PUT', headers: { 'Content-Type': 'application/json' } },
        JSON.stringify(body)
      ).then(function (response) {
        const responseStatusCode = response.statusCode;

        log({
          Name: 'DuplicateTransactionChecker',
          Type: 'Response',
          TraceId: traceId,
          EventName: 'DuplicateTransactionCheckerWrite',
          ResponseStatusCode: responseStatusCode,
          ResponseHeaders: {},
          ResponseBody: response.body
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
        ResponseBody: response.body,
        Message: 'Error during request to Stape Store'
      });

      return undefined;
    }
  });
}

function getStapeStoreBaseUrl(data) {
  const containerIdentifier = getRequestHeader('x-gtm-identifier');
  const defaultDomain = getRequestHeader('x-gtm-default-domain');
  const containerApiKey = getRequestHeader('x-gtm-api-key');
  const collectionPath =
    'collections/' + enc(data.stapeStoreCollectionName || 'default') + '/documents';

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

function firestoreChecker(data, documentId) {
  const projectId = data.firebaseProjectId;
  const documentPath = data.firebasePath + '/' + documentId;

  return Firestore.read(documentPath, { projectId: projectId })
    .then(function (result) {
      if (result.exists) {
        return true;
      } else {
        return Firestore.write(documentPath, {
          projectId: projectId,
          data: { transaction_id: documentId }
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

scenarios: []


___NOTES___

Created on 7/23/2024, 1:55:47 PM


