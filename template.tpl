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
  }
]


___TESTS___

scenarios: []


___NOTES___

Created on 7/23/2024, 1:55:47 PM


