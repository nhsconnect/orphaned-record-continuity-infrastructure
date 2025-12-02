import {DescribeServicesCommand} from "@aws-sdk/client-ecs";
import {ecsClient as client} from "./clients";

export const waitForServiceToRestart = async (service, cluster) => {
    const describeServicesCommand = new DescribeServicesCommand({ services: [service], cluster });

    const RETRY_COUNT = 10;
    const POLLING_INTERVAL = 20000;
    for (let i = 0; i < RETRY_COUNT; i++) {
        const response = await client.send(describeServicesCommand);
        const deployments = response.services[0].deployments;
        console.log('try: ', i, 'deployments status:', deployments.map(deployment => deployment.status))
        if (deployments.every(deployment => deployment.status !== 'ACTIVE')) {
            console.log('No ACTIVE deployments. Assuming restart finished')
            break;
        }
        await sleep(POLLING_INTERVAL);
    }
}

const sleep = ms => {
    return new Promise(resolve => setTimeout(resolve, ms));
};