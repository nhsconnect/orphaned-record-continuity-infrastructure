import { when } from "jest-when";
import { generateApiKeys } from "../generate-api-keys";
import { deleteApiKey, generateApiKey, getParam, getParamsByPath, } from "../../aws-clients/ssm-client";
import { restartServices } from "../../restart-services/restart-services";
import { initializeConfig } from "../../config";

jest.mock("../../aws-clients/ssm-client");
jest.mock("../../restart-services/restart-services");
jest.mock("../../config");

describe("generateApiKeys", () => {
  const ssmPath = `/repo/nhs-environment/user-input/service-api-keys`;

  beforeEach(() => {
    when(initializeConfig).calledWith().mockReturnValue({
      nhsEnvironment: "nhs-environment",
      isStrictEnvironment: false,
    });
  });

  afterEach(() => jest.resetAllMocks());

  it("should not create new ssm parameter for api keys that already exist in ssm", async () => {

    when(getParam)
      .calledWith("/repo/nhs-environment/user-input/service-api-keys")
      .mockResolvedValue("/repo/env/api-keys/key,/repo/env/api-keys/key-1");

    when(getParamsByPath)
      .calledWith("/repo/nhs-environment/user-input/api-keys/")
      .mockResolvedValue([
        "/repo/env/api-keys/key",
        "/repo/env/api-keys/key-1",
      ]);

    await generateApiKeys(ssmPath, true);

    expect(getParam).toHaveBeenCalledWith(
      "/repo/nhs-environment/user-input/service-api-keys"
    );

    expect(generateApiKey).not.toHaveBeenCalled();
    expect(restartServices).toHaveBeenCalledWith([]);
  });

  it("should create new ssm parameter for api key if it is not found", async () => {
    when(getParam)
      .calledWith("/repo/nhs-environment/user-input/service-api-keys")
      .mockResolvedValue("/repo/env/api-keys/key," +
        "/repo/env/api-keys/key-1," +
        "/repo/env/api-keys/key-2");

    when(getParamsByPath)
      .calledWith("/repo/nhs-environment/user-input/api-keys/")
      .mockResolvedValue([
        "/repo/env/api-keys/key",
        "/repo/env/api-keys/key-1",
      ]);

    await generateApiKeys(ssmPath, true);

    expect(generateApiKey).toHaveBeenCalledWith("/repo/env/api-keys/key-2");
    expect(restartServices).toHaveBeenCalledWith(["/repo/env/api-keys/key-2"]);
  });

  it("should allow newlines as delimiters in service api key list", async () => {
    when(getParam)
      .calledWith("/repo/nhs-environment/user-input/service-api-keys")
      .mockResolvedValue(`/repo/env/api-keys/key
/repo/env/api-keys/key-1`);

    when(getParamsByPath)
      .calledWith("/repo/nhs-environment/user-input/api-keys/")
      .mockResolvedValue(["/repo/env/api-keys/key"]);

    await generateApiKeys(ssmPath, true);

    expect(generateApiKey).toHaveBeenCalledWith("/repo/env/api-keys/key-1");
    expect(restartServices).toHaveBeenCalledWith(["/repo/env/api-keys/key-1"]);
  });

  it("should delete ssm parameter for api key not expected", async () => {
    when(getParam)
      .calledWith("/repo/nhs-environment/user-input/service-api-keys")
      .mockResolvedValue("/repo/env/api-keys/key,/repo/env/api-keys/key-1");

    when(getParamsByPath)
      .calledWith("/repo/nhs-environment/user-input/api-keys/")
      .mockResolvedValue([
        "/repo/env/api-keys/key",
        "/repo/env/api-keys/key-1",
        "/repo/env/api-keys/unexpected-key",
      ]);

    await generateApiKeys(ssmPath, true);

    expect(generateApiKey).not.toHaveBeenCalled();
    expect(deleteApiKey).toHaveBeenCalledWith(
      "/repo/env/api-keys/unexpected-key"
    );
    expect(restartServices).toHaveBeenCalledWith([
      "/repo/env/api-keys/unexpected-key",
    ]);
  });

  it("should both delete and generate api keys", async () => {
    when(getParam)
      .calledWith("/repo/nhs-environment/user-input/service-api-keys")
      .mockResolvedValue(
        "/repo/env/api-keys/key," +
        "/repo/env/api-keys/actual-key");

    when(getParamsByPath)
      .calledWith("/repo/nhs-environment/user-input/api-keys/")
      .mockResolvedValue([
        "/repo/env/api-keys/key",
        "/repo/env/api-keys/unexpected-key",
      ]);

    await generateApiKeys(ssmPath, true);

    expect(generateApiKey).toHaveBeenCalledWith(
      "/repo/env/api-keys/actual-key"
    );
    expect(deleteApiKey).toHaveBeenCalledWith(
      "/repo/env/api-keys/unexpected-key"
    );
    expect(restartServices).toHaveBeenCalledWith([
      "/repo/env/api-keys/actual-key",
      "/repo/env/api-keys/unexpected-key",
    ]);
  });

  it("should not process user api keys", async () => {
    const userApiKey = "/repo/env/api-keys/api-key-user/joe.pesci";
    when(getParam)
      .calledWith("/repo/nhs-environment/user-input/service-api-keys")
      .mockResolvedValue("/repo/env/api-keys/key,/repo/env/api-keys/actual-key");

    when(getParamsByPath)
      .calledWith("/repo/nhs-environment/user-input/api-keys/")
      .mockResolvedValue([
        "/repo/env/api-keys/key",
        "/repo/env/api-keys/unexpected-key",
        userApiKey,
      ]);

    await generateApiKeys(ssmPath, true);

    expect(generateApiKey).not.toHaveBeenCalledWith(userApiKey);
    expect(deleteApiKey).not.toHaveBeenCalledWith(userApiKey);
    expect(restartServices).toHaveBeenCalledWith(
      expect.not.arrayContaining([userApiKey])
    );
  });

  it("should throw an error when cannot get list of api keys from ssm", async () => {
    const wrongSsmPath = `/repo/not-found/user-input/service-api-keys`;

    when(getParam)
      .calledWith(wrongSsmPath)
      .mockResolvedValue(null);

    await expect(
      generateApiKeys(wrongSsmPath, true)
    ).rejects.toEqual(new Error("Unable to retrieve list of api keys"));

    expect(getParam).toHaveBeenCalledWith(
      "/repo/not-found/user-input/service-api-keys"
    );
    expect(generateApiKey).not.toHaveBeenCalled();
    expect(restartServices).not.toHaveBeenCalled();
  });
});
