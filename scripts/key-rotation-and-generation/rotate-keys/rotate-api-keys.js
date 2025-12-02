import { initializeConfig } from "../config";
import {
  getParamsByPath,
  getRotateApiKeyTag,
  removeRotateApiKeyTag,
  rotateApiKey,
} from "../aws-clients/ssm-client";
import { restartServices } from "../restart-services/restart-services";

export const rotateApiKeys = async (isService) => {
  console.log("Starting key rotation process");
  const { nhsEnvironment } = initializeConfig();

  try {
    const apiKeysArray = await getParamsByPath(
      `/repo/${nhsEnvironment}/user-input/api-keys/`
    );
    let rotatedApiKeys = [];
    if (!isService) {
      const userApiKeys = apiKeysArray.filter((apiKey) =>
        apiKey.includes("/api-key-user/")
      );
      rotatedApiKeys = await rotation(userApiKeys);
    } else {
      const serviceApiKeys = apiKeysArray.filter(
        (apiKey) => !apiKey.includes("/api-key-user/")
      );
      rotatedApiKeys = await rotation(serviceApiKeys);
    }
    await restartServices(rotatedApiKeys);
  } catch (e) {
    console.log(e);
    throw e;
  }
};

async function rotation(apiKeysArray) {
  let rotatedApiKeys = [];
  for (const apiKey of apiKeysArray) {
    const rotateApiKeyTag = await getRotateApiKeyTag(apiKey);
    if (rotateApiKeyTag) {
      await rotateApiKey(apiKey);
      await removeRotateApiKeyTag(apiKey);
      rotatedApiKeys.push(apiKey);
    }
  }
  console.log(`Total keys rotated ${rotatedApiKeys.length}`);
  return rotatedApiKeys;
}
