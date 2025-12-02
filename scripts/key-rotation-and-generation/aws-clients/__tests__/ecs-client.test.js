import { ecsClient } from "../clients";
import { restartECS } from "../ecs-client";
import { initializeConfig } from "../../config";
import { when } from "jest-when";
import { waitForServiceToRestart } from "../ecs-client-service-restart";
import { UpdateServiceCommand } from "@aws-sdk/client-ecs";

jest.mock("@aws-sdk/client-ecs");
jest.mock("../clients");
jest.mock("../../config");
jest.mock("../ecs-client-service-restart");

describe("ecs-client", () => {
  beforeEach(() => {
    when(initializeConfig).calledWith().mockReturnValue({
      nhsEnvironment: "dev",
      isStrictEnvironment: false,
    });
  });
  afterEach(() => jest.resetAllMocks());

  describe("restartEcs", () => {
    it("should call send command to ecs client to update service and cluster", async () => {
      const serviceName = "pds-adaptor";
      const mockCommand = {
        forceNewDeployment: true,
        service: "dev-pds-adaptor-service",
        cluster: "dev-pds-adaptor-ecs-cluster",
      };
      when(UpdateServiceCommand)
        .calledWith(mockCommand)
        .mockReturnValue(mockCommand);
      when(waitForServiceToRestart)
        .calledWith("dev-pds-adaptor-service", "dev-pds-adaptor-cluster")
        .mockResolvedValue("sdgfd");

      await restartECS(serviceName);
      expect(UpdateServiceCommand).toBeCalledWith(mockCommand);
      expect(ecsClient.send).toBeCalledWith(mockCommand);
      expect(waitForServiceToRestart).toBeCalledWith(
        "dev-pds-adaptor-service",
        "dev-pds-adaptor-ecs-cluster"
      );
    });
    it("should call send command to not duplicate service name to update service and cluster", async () => {
      const serviceName = "suspension-service";
      const mockCommand = {
        forceNewDeployment: true,
        service: "dev-suspension-service",
        cluster: "dev-suspension-service-ecs-cluster",
      };
      when(UpdateServiceCommand)
        .calledWith(mockCommand)
        .mockReturnValue({ command: "updateCommand" });
      await restartECS(serviceName);
      expect(UpdateServiceCommand).toBeCalledWith(mockCommand);
      expect(ecsClient.send).toBeCalledWith({ command: "updateCommand" });
      expect(waitForServiceToRestart).toBeCalledWith(
        "dev-suspension-service",
        "dev-suspension-service-ecs-cluster"
      );
    });
  });
});
