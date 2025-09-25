import { generateApiKeys } from "./generate-api-keys";
import { initializeConfig } from "../config";

const { nhsEnvironment } = initializeConfig();

generateApiKeys(
  `/repo/${nhsEnvironment}/user-input/external/repo-dev-list`,
  false
).catch(() => {
  process.exit(1);
});
