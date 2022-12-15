const {run} = require("hardhat");

const verify = async(contractAddress, args) => {
    await run("verify:verify", {
        address: contractAddress,
        constructorArguments: args,
    })
    .then(() => {
        console.log("Contract verified: ", contractAddress);
    })
    .catch(err => {
        if(err.message.toLowerCase().includes("already verified")) {
            console.log("Contract already verified: ", contractAddress);
        }
        else{
            console.log("Contract verification failed: ", contractAddress);
            console.log(err);
        }
    })
}
module.exports = {
    verify
}