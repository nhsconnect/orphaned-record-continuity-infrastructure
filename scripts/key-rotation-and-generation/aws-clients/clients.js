import {ECSClient} from "@aws-sdk/client-ecs"
import {SSMClient} from "@aws-sdk/client-ssm"

const config = { region: "eu-west-2" }

export const ecsClient = new ECSClient(config);
export const ssmClient = new SSMClient(config);
