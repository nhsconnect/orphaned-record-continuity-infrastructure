import { UpdateServiceCommand } from "@aws-sdk/client-ecs";
import { ecsClient as client } from "./clients";
import { initializeConfig } from "../config";
import { waitForServiceToRestart } from "./ecs-client-service-restart";

export const restartECS = async (serviceName) => {
  let service;
  if (serviceName.endsWith("service")) {
    service = `${initializeConfig().nhsEnvironment}-${serviceName}`;
  } else {
    service = `${initializeConfig().nhsEnvironment}-${serviceName}-service`;
  }
  const cluster = `${
    initializeConfig().nhsEnvironment
  }-${serviceName}-ecs-cluster`;
  const updateServiceCommand = new UpdateServiceCommand({
    forceNewDeployment: true,
    service,
    cluster,
  });
  console.log(`Restarting ECS For Cluster ${cluster}, Service: ${service}`);
  await client.send(updateServiceCommand);

  await waitForServiceToRestart(service, cluster);
};
