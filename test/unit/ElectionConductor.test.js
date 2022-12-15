const {assert, expect} = require("chai")
const {ethers, network, getNamedAccounts, deployments} = require("hardhat");
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")

// ! test only when not on mainnet 
!developmentChains.includes(hre.network.name)
    ? describe.skip :
    describe("ElectionConductor", () => {
        let electionConductor, deployer;
        const chainId = network.config.chainId;

        beforeEach(async () => {
            deployer = (await getNamedAccounts()).deployer;
            // ! deploy contracts and grab electionConductor
            await deployments.fixture(["all"]);
            electionConductor = await ethers.getContract("ElectionConductor", deployer);
        })

        describe("createElection & getRegisteredElection", () => {
            it("Should create election with the correct details", async() => {
                const electionName = "Test Election";
                const electionDescription = "Test Election Description";
                    await electionConductor.createElection(
                        electionName,
                        electionDescription
                    )
                    
                    const result = await electionConductor.getRegisteredElection(deployer)
                    assert.equal(result.electionName,electionName);
                    assert.equal(result.electionDescription,electionDescription);
                    assert.equal(await electionConductor.getElectionAddress(deployer), result.electionAddress)
                    assert.equal(electionConductor.address, await electionConductor.getAuthorityAddress(deployer))
                })
            })
            
        describe("Creating an election as we will need it from now on", () => {
            beforeEach(async() => {
                const electionName = "Test Election";
                const electionDescription = "Test Election Description";
                await electionConductor.createElection(
                    electionName,
                    electionDescription
                )     
            })
            describe("Add candidate", () => {
                it("Should allow only authority to add candidate", async () => {
                    const name = "Name"
                    const img = "imgUrl"
                    const email = "email@1234"
                    const accounts = await ethers.getSigners();
                    assert.equal(0, await electionConductor.getNumofCandidates(deployer))
                    await electionConductor.addCandidate(
                        deployer,
                        name,
                        img,
                        email
                    )
                    assert.equal(1, await electionConductor.getNumofCandidates(deployer))
                    const connectedElection = await electionConductor.connect(accounts[1]);
                    await expect(
                        connectedElection.addCandidate(
                            deployer,
                            name,
                            img,
                            email
                        )
                    ).to.be.revertedWith("NotAuthorized")
                    
                    await expect(electionConductor.addCandidate(
                        accounts[1].address,
                        name,
                        img,
                        email
                    )).to.be.revertedWith("ElectionNotFound");
                            
                })
            })
            // ! NOTE - from now on we will be pretending that the Election object will always exist 
            // ! So we don't need to check if the election exists or not 
            // declare uint8 with value = 1
            const candidateId = 1;
            describe("Register Voter", () => {
                it("Should allow voters to register themselves only if election is in appropriate state", async () => {
                    const accounts = await ethers.getSigners();
                    await electionConductor.registerVoter(
                        deployer,
                        accounts[1].address,
                        candidateId
                    )
                    const result = await electionConductor.getPendingVoter(deployer, accounts[1].address)
                    // returns - [voterAddress, candidateId, isVoted]
                    assert.equal(result[0], accounts[1].address)
                    assert.equal(result[1], candidateId)
                    assert.equal(result[2], false)
                })
            })
            describe("Add Voter", () => {
                it("Should allow only registered voters to vote", async   () => {
                    // ! first allow a voter register themselves
                    const accounts = await ethers.getSigners();
                    
                    await electionConductor.registerVoter(
                        deployer,
                        accounts[1].address,
                        candidateId
                    )

                    await electionConductor.addVoters(
                        deployer,
                        accounts[1].address,
                    )
                    // ! now this voter should be added to the mapping of voters
                    const result = await electionConductor.getVoterDetails(
                        deployer,
                        accounts[1].address
                    )
                    assert.equal(result[0], accounts[1].address)
                    assert.equal(result[1], candidateId)
                    assert.equal(result[2], false)

                    // ! also only authority should be able to add voter
                    const connectedElection = await electionConductor.connect(accounts[1]);
                    await expect(
                        connectedElection.addVoters(
                            deployer,
                            accounts[1].address,
                        )).to.be.revertedWith("NotAuthorized")
                })
            })
            describe("vote & final declaration of winner", () => {
                beforeEach(async () => {
                    const accounts = await ethers.getSigners();
                    await electionConductor.addCandidate(
                        deployer,
                        "Rohit",
                        "imgUrl1",
                        "email1@1234"
                    )
                    await electionConductor.addCandidate(
                        deployer,
                        "Disha",
                        "imgUrl2",
                        "email2@1234"
                    )
            
                    for(let i = 1; i < 6; i++) {
                        await electionConductor.registerVoter(
                            deployer,
                            accounts[i].address,
                            candidateId
                        )
                    }
                })
                it("Should allow only registered voters to vote", async () => {
                    const accounts = await ethers.getSigners();
                    
                    // ! first check if election has started or not
                    await expect(electionConductor.vote(
                        deployer,
                        accounts[5].address,
                        1
                        )).to.be.revertedWith("ElectionNotStarted")
                        
                        // ! now start the election
                        await electionConductor.startElection(deployer)
                        // ! check if we revert when voter has not been added to the voting list by the authority
                        await expect(electionConductor.vote(
                            deployer,
                            accounts[4].address,
                            1
                            )).to.be.revertedWith("VoterNotFound")  
                            
                        // Add voters from pending voters mapping to voters mapping - only authority can do this
                        for(let i = 1; i < 6; i++) {
                            await electionConductor.addVoters(
                                deployer,
                                accounts[i].address,
                            )
                        }

                        // ! start voting - Disha is going to win
                        for(let i = 1; i < 6; i++) {
                            const connectedElectionContract = await electionConductor.connect(accounts[i]);
                            await connectedElectionContract.vote(
                                deployer,
                                accounts[i].address,
                                i % 2 == 0 ? 1 : 2 // ? 2nd candidate will win
                            )
                        }
                        

                        // ! end election & declare winner
                        await electionConductor.endElection(deployer)
                        await electionConductor.declareWinnerCandidate(deployer)
                        const winnerCandidate = await electionConductor.getWinnerCandidateId(deployer)
                        assert.equal(winnerCandidate.toString(), "2")
                })
            })
        }) 
    })