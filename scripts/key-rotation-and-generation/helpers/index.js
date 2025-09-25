import { initializeConfig } from "../config";

export const convertStringListToArray = (apiKeysString) => {
  if (!apiKeysString) {
    throw new Error("Unable to retrieve list of api keys");
  } else {
    return apiKeysString.split(/[,\n]+/);
  }
};

export const convertUserListToUserListParamArray = (userApiKeys) => {
  const { nhsEnvironment, isStrictEnvironment } = initializeConfig();

  if (userApiKeys.length === 0) {
    throw new Error("Expected user api key list is empty");
  } else {
    const paramList = [];
    for (const apiKey of userApiKeys) {
      addApiKeyToParamList(apiKey, paramList);
    }
    return paramList;
  }

  function addApiKeyToParamList(apiKey, paramList) {
    if (!isStrictEnvironment) {
      const apiKeyEhrOUtServicePath = `/repo/${nhsEnvironment}/user-input/api-keys/ehr-out-service/api-key-user/${apiKey}`;
      const apiKeyPdsAdaptorPath = `/repo/${nhsEnvironment}/user-input/api-keys/pds-adaptor/api-key-user/${apiKey}`;

      paramList.push(apiKeyEhrOUtServicePath);
      paramList.push(apiKeyPdsAdaptorPath);
    }
    const apiKeyEhrRepoPath = `/repo/${nhsEnvironment}/user-input/api-keys/ehr-repo/api-key-user/${apiKey}`;
    const apiKeyGp2GpMessengerPath = `/repo/${nhsEnvironment}/user-input/api-keys/gp2gp-messenger/api-key-user/${apiKey}`;

    paramList.push(apiKeyEhrRepoPath);
    paramList.push(apiKeyGp2GpMessengerPath);
  }
};
