import { rotateApiKeys } from "./rotate-api-keys";

rotateApiKeys(false).catch(() => {
  process.exit(1);
});
