const {ethers,network} = require("hardhat");
const { VERIFICATION_BLOCK_CONFIRMATIONS,developmentChains,networkConfig, electionABI } = require("../helper-hardhat-config")
const {verfiy, verify} = require("../utils/verify")

module.exports = async (hre) => {
    const {deployments, getNamedAccounts} = hre;
    const {deploy, log} = deployments;
    const {deployer} = await getNamedAccounts();

    const waitBlockConfirmations = developmentChains.includes(network.name)
        ? 1
        : VERIFICATION_BLOCK_CONFIRMATIONS;

    log("Deploying ElectionConductor...");
    const electionConductor = await deploy("ElectionConductor", {
        from: deployer,
        args: [],
        log: true,
        waitConfirmations: waitBlockConfirmations,
    })
    // get Election contract
    // const electionContract = await ethers.getContract("Election");
    log("ElectionConductor deployed to:", electionConductor.address);
    log("---------------------------------------------------------")
    
    if(!developmentChains.includes(network.name)) {
        await verify(electionConductor.address, [])
    }
}
module.exports.tags = ["all","electionConductor"];
