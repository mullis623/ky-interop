@description('Name of the Logic App.')
param logicAppName string = 'ipaas-getaddress'

@description('Location of the Logic App.')
param logicAppLocation string = resourceGroup().location
param bingmaps_name string = 'bingmaps'
param bingmaps_displayName string = 'iPaaS Bing Maps'

@description('API Key')
@secure()
param bingmaps_api_key string

resource bingmaps_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  location: logicAppLocation
  name: bingmaps_name
  properties: {
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${logicAppLocation}/managedApis/bingmaps'
    }
    displayName: bingmaps_displayName
    parameterValues: {
      api_key: bingmaps_api_key
    }
  }
}

resource logicAppName_resource 'Microsoft.Logic/workflows@2016-06-01' = {
  name: logicAppName
  location: logicAppLocation
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      staticResults: {
        Get_Address_From_Geo_Coordinates0: {
          status: 'Succeeded'
          outputs: {
            body: {
              '__type': 'Location:http://schemas.microsoft.com/search/local/ws/rest/v1'
              address: {
                addressLine: '23929 Mill Wheel Pl'
                adminDistrict: 'VA'
                adminDistrict2: 'Loudoun Co.'
                countryRegion: 'United States'
                countryRegionIso2: 'US'
                formattedAddress: '4 Tuscan Ct, Cumberland, RI 02864, United States'
                locality: 'Aldie'
                postalCode: '20105'
              }
              bbox: {
                eastLongitude: '-77.56646722499544'
                northLatitude: '38.96058671757068'
                southLatitude: '38.952861282429325'
                westLongitude: '-77.57971277500455'
              }
              confidence: 'High'
              entityType: 'Address'
              geocodePoints: {
                calculationMethod: 'Rooftop'
                coordinates: {
                  combined: '38.956724,-77.57309'
                  latitude: '38.956724'
                  longitude: '-77.57309'
                }
                type: 'Point'
                usageTypes: [
                  'Display'
                ]
              }
              matchCodes: [
                'Good'
              ]
              name: '23929 Mill Wheel Pl, Aldie, VA 20105, United States'
              point: {
                coordinates: {
                  combined: '38.956724,-77.57309'
                  latitude: '38.956724'
                  longitude: '-77.57309'
                }
                type: 'Point'
              }
            }
            headers: {}
            statusCode: 'OK'
          }
        }
        Parse_Bing_Maps_Response_JSON1: {
          status: 'Succeeded'
        }
      }
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              properties: {
                geoLatCoordinate: {
                  type: 'string'
                }
                geoLongCoordinate: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
      }
      actions: {
        Condition: {
          actions: {
            Response: {
              runAfter: {}
              type: 'Response'
              kind: 'Http'
              inputs: {
                body: '@body(\'Get_Address_From_Geo_Coordinates\')?[\'address\']?[\'formattedAddress\']'
                statusCode: 200
              }
            }
          }
          runAfter: {
            Parse_Bing_Maps_Response_JSON: [
              'Succeeded'
            ]
          }
          else: {
            actions: {
              Parse_Bing_Maps_Error_Response_JSON: {
                runAfter: {}
                type: 'ParseJson'
                inputs: {
                  content: '@body(\'Get_Address_From_Geo_Coordinates\')'
                  schema: {
                    properties: {
                      authenticationResultCode: {
                        type: 'string'
                      }
                      brandLogoUri: {
                        type: 'string'
                      }
                      copyright: {
                        type: 'string'
                      }
                      errorDetails: {
                        items: {
                          type: 'string'
                        }
                        type: 'array'
                      }
                      resourceSets: {
                        type: 'array'
                      }
                      statusCode: {
                        type: 'integer'
                      }
                      statusDescription: {
                        type: 'string'
                      }
                      traceId: {
                        type: 'string'
                      }
                    }
                    type: 'object'
                  }
                }
              }
              Response_2: {
                runAfter: {
                  Parse_Bing_Maps_Error_Response_JSON: [
                    'Succeeded'
                  ]
                }
                type: 'Response'
                kind: 'Http'
                inputs: {
                  body: '@body(\'Parse_Bing_Maps_Error_Response_JSON\')?[\'errorDetails\']'
                  statusCode: '@body(\'Parse_Bing_Maps_Error_Response_JSON\')?[\'statusCode\']'
                }
              }
            }
          }
          expression: {
            and: [
              {
                equals: [
                  '@empty(body(\'Parse_Bing_Maps_Response_JSON\')?[\'name\'])'
                  false
                ]
              }
            ]
          }
          type: 'If'
        }
        Get_Address_From_Geo_Coordinates: {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'bingmaps\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/REST/v1/Locations/pointPlaceHolder'
            queries: {
              include: true
              includeNeighborhood: true
              latitude: '@triggerBody()?[\'geoLatCoordinate\']'
              longitude: '@triggerBody()?[\'geoLongCoordinate\']'
            }
          }
          runtimeConfiguration: {
            staticResult: {
              staticResultOptions: 'Disabled'
              name: 'Get_Address_From_Geo_Coordinates0'
            }
          }
        }
        Parse_Bing_Maps_Response_JSON: {
          runAfter: {
            Get_Address_From_Geo_Coordinates: [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@body(\'Get_Address_From_Geo_Coordinates\')'
            schema: {
              properties: {
                '__type': {
                  type: 'string'
                }
                address: {
                  properties: {
                    addressLine: {
                      type: 'string'
                    }
                    adminDistrict: {
                      type: 'string'
                    }
                    adminDistrict2: {
                      type: 'string'
                    }
                    countryRegion: {
                      type: 'string'
                    }
                    countryRegionIso2: {
                      type: 'string'
                    }
                    formattedAddress: {
                      type: 'string'
                    }
                    intersection: {
                      properties: {
                        baseStreet: {
                          type: 'string'
                        }
                        displayName: {
                          type: 'string'
                        }
                        intersectionType: {
                          type: 'string'
                        }
                        secondaryStreet1: {
                          type: 'string'
                        }
                        secondaryStreet2: {
                          type: 'string'
                        }
                      }
                      type: 'object'
                    }
                    locality: {
                      type: 'string'
                    }
                    neighborhood: {
                      type: 'string'
                    }
                    postalCode: {
                      type: 'string'
                    }
                  }
                  type: 'object'
                }
                bbox: {
                  properties: {
                    eastLongitude: {
                      type: 'number'
                    }
                    northLatitude: {
                      type: 'number'
                    }
                    southLatitude: {
                      type: 'number'
                    }
                    westLongitude: {
                      type: 'number'
                    }
                  }
                  type: 'object'
                }
                confidence: {
                  type: 'string'
                }
                entityType: {
                  type: 'string'
                }
                geocodePoints: {
                  properties: {
                    calculationMethod: {
                      type: 'string'
                    }
                    coordinates: {
                      properties: {
                        combined: {
                          type: 'string'
                        }
                        latitude: {
                          type: 'number'
                        }
                        longitude: {
                          type: 'number'
                        }
                      }
                      type: 'object'
                    }
                    type: {
                      type: 'string'
                    }
                    usageTypes: {
                      items: {
                        type: 'string'
                      }
                      type: 'array'
                    }
                  }
                  type: 'object'
                }
                matchCodes: {
                  items: {
                    type: 'string'
                  }
                  type: 'array'
                }
                name: {
                  type: 'string'
                }
                point: {
                  properties: {
                    coordinates: {
                      properties: {
                        combined: {
                          type: 'string'
                        }
                        latitude: {
                          type: 'number'
                        }
                        longitude: {
                          type: 'number'
                        }
                      }
                      type: 'object'
                    }
                    type: {
                      type: 'string'
                    }
                  }
                  type: 'object'
                }
              }
              type: 'object'
            }
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          bingmaps: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${logicAppLocation}/managedApis/bingmaps'
            connectionId: bingmaps_name_resource.id
            connectionName: bingmaps_name
          }
        }
      }
    }
  }
}
