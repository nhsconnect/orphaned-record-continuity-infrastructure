import { when } from "jest-when";
import { rotateApiKeys } from "../rotate-api-keys";
import {
  getParamsByPath,
  getRotateApiKeyTag,
  removeRotateApiKeyTag,
  rotateApiKey,
} from "../../aws-clients/ssm-client";
import { initializeConfig } from "../../config";
import { restartServices } from "../../restart-services/restart-services";

jest.mock("../../aws-clients/ssm-client");
jest.mock("../../restart-services/restart-services");
jest.mock("../../config");

describe("rotateApiKeys", () => {
  initializeConfig.mockReturnValue({ nhsEnvironment: "env" });

  beforeEach(() => {
    when(getRotateApiKeyTag)
      .calledWith("/repo/env/api-keys/key")
      .mockResolvedValue(true)
      .calledWith("/repo/env/api-keys/key-1")
      .mockResolvedValue(false)
      .calledWith("/repo/env/api-keys/key-2")
      .mockResolvedValue(false);
  });

  afterEach(() => {
    getRotateApiKeyTag.mockRestore();
    rotateApiKey.mockRestore();
    removeRotateApiKeyTag.mockRestore();
    restartServices.mockRestore();
  });

  it("should rotate api key when the parameter is tagged with RotateApiKey", async () => {
    getParamsByPath.mockResolvedValueOnce([
      "/repo/env/api-keys/key",
      "/repo/env/api-keys/key-1",
    ]);

    await rotateApiKeys(true);

    expect(getParamsByPath).toHaveBeenCalledWith(
      "/repo/env/user-input/api-keys/"
    );
    expect(getRotateApiKeyTag).toHaveBeenCalledWith("/repo/env/api-keys/key");
    expect(getRotateApiKeyTag).toHaveBeenCalledWith("/repo/env/api-keys/key-1");
    expect(getRotateApiKeyTag).toHaveBeenCalledTimes(2);
    expect(rotateApiKey).toHaveBeenCalledWith("/repo/env/api-keys/key");
    expect(rotateApiKey).toHaveBeenCalledTimes(1);
    expect(removeRotateApiKeyTag).toHaveBeenCalledWith(
      "/repo/env/api-keys/key"
    );
    expect(restartServices).toHaveBeenCalledWith(["/repo/env/api-keys/key"]);
  });

  it("should not rotate api keys when parameters are not tagged", async () => {
    getParamsByPath.mockResolvedValueOnce([
      "/repo/env/api-keys/key-1",
      "/repo/env/api-keys/key-2",
    ]);

    await rotateApiKeys(true);

    expect(getParamsByPath).toHaveBeenCalledWith(
      "/repo/env/user-input/api-keys/"
    );
    expect(getRotateApiKeyTag).toHaveBeenCalledWith("/repo/env/api-keys/key-1");
    expect(getRotateApiKeyTag).toHaveBeenCalledWith("/repo/env/api-keys/key-2");
    expect(getRotateApiKeyTag).toHaveBeenCalledTimes(2);
    expect(rotateApiKey).not.toHaveBeenCalled();
    expect(removeRotateApiKeyTag).not.toHaveBeenCalled();
    expect(restartServices).toHaveBeenCalledWith([]);
  });

  it("should only rotate service api keys, not user api keys when isService is true", async () => {
    getParamsByPath.mockResolvedValueOnce([
      "/repo/env/api-keys/key",
      "/repo/env/api-keys/key-1",
      "/repo/env/api-keys/api-key-user/user",
      "/repo/env/api-keys/api-key-user/user-1",
    ]);
    await rotateApiKeys(true);

    expect(getParamsByPath).toHaveBeenCalledWith(
      "/repo/env/user-input/api-keys/"
    );
    expect(getRotateApiKeyTag).not.toHaveBeenCalledWith(
      "/repo/env/api-keys/api-key-user/user"
    );
    expect(getRotateApiKeyTag).not.toHaveBeenCalledWith(
      "/repo/env/api-keys/api-key-user/user-1"
    );
    expect(getRotateApiKeyTag).toHaveBeenCalledWith("/repo/env/api-keys/key");
    expect(getRotateApiKeyTag).toHaveBeenCalledWith("/repo/env/api-keys/key-1");

    expect(rotateApiKey).not.toHaveBeenCalledWith(
      "/repo/env/api-keys/api-key-user/user"
    );
    expect(removeRotateApiKeyTag).not.toHaveBeenCalledWith(
      "/repo/env/api-keys/api-key-user/user"
    );

    expect(restartServices).toHaveBeenCalledWith(["/repo/env/api-keys/key"]);
    expect(restartServices).toHaveBeenCalledTimes(1);
  });
});
