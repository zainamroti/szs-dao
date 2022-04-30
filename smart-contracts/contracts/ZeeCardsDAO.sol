// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// We will add the Interfaces here
import "./IFakeNFTMarketplace.sol";
import "./IZeeCardsNFT.sol";

contract ZeeCardsDAO is Ownable {
    // We will write contract code here
    // Create a struct named Proposal containing all relevant information
        struct Proposal {
            // nftTokenId - the tokenID of the NFT to purchase from FakeNFTMarketplace if the proposal passes
            uint256 nftTokenId;
            // deadline - the UNIX timestamp until which this proposal is active. Proposal can be executed after the deadline has been exceeded.
            uint256 deadline;
            // yayVotes - number of yay votes for this proposal
            uint256 yayVotes;
            // nayVotes - number of nay votes for this proposal
            uint256 nayVotes;
            // executed - whether or not this proposal has been executed yet. Cannot be executed before the deadline has been exceeded.
            bool executed;
            // voters - a mapping of ZeeCardsNFT tokenIDs to booleans indicating whether that NFT has already been used to cast a vote or not
            mapping(uint256 => bool) voters;
        }

        // Create a mapping of ID to Proposal
        mapping(uint256 => Proposal) public proposals;
        // Number of proposals that have been created
        uint256 public numProposals;

        IFakeNFTMarketplace nftMarketplace;
        IZeeCardsNFT zeeCardsNFT;

        // Create a payable constructor which initializes the contract
        // instances for FakeNFTMarketplace and ZeeCardsNFT
        // The payable allows this constructor to accept an ETH deposit when it is being deployed
        constructor(address _nftMarketplace, address _zeeCardsNFT) payable {
            nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
            zeeCardsNFT = IZeeCardsNFT(_zeeCardsNFT);
        }

        // Create a modifier which only allows a function to be
        // called by someone who owns at least 1 ZeeCardsNFT
        modifier nftHolderOnly() {
            require(zeeCardsNFT.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
            _;
        }

        /// @dev createProposal allows a ZeeCardsNFT holder to create a new proposal in the DAO
        /// @param _nftTokenId - the tokenID of the NFT to be purchased from FakeNFTMarketplace if this proposal passes
        /// @return Returns the proposal index for the newly created proposal
        function createProposal(uint256 _nftTokenId)
            external
            nftHolderOnly
            returns (uint256)
        {
            require(nftMarketplace.available(_nftTokenId), "NFT_NOT_FOR_SALE");
            Proposal storage proposal = proposals[numProposals];
            proposal.nftTokenId = _nftTokenId;
            // Set the proposal's voting deadline to be (current time + 5 minutes)
            proposal.deadline = block.timestamp + 5 minutes;

            numProposals++;

            return numProposals - 1;
        }

        // Create a modifier which only allows a function to be
        // called if the given proposal's deadline has not been exceeded yet
        modifier activeProposalOnly(uint256 proposalIndex) {
            require(
                proposals[proposalIndex].deadline > block.timestamp,
                "DEADLINE_EXCEEDED"
            );
            _;
        }

        // Create an enum named Vote containing possible options for a vote
        enum Vote {
            YAY, // YAY = 0
            NAY // NAY = 1
        }

        /// @dev voteOnProposal allows a ZeeCardsNFT holder to cast their vote on an active proposal
        /// @param proposalIndex - the index of the proposal to vote on in the proposals array
        /// @param vote - the type of vote they want to cast
        function voteOnProposal(uint256 proposalIndex, Vote vote)
            external
            nftHolderOnly
            activeProposalOnly(proposalIndex)
        {
            Proposal storage proposal = proposals[proposalIndex];

            uint256 voterNFTBalance = zeeCardsNFT.balanceOf(msg.sender);
            uint256 numVotes = 0;

            // Calculate how many NFTs are owned by the voter
            // that haven't already been used for voting on this proposal
            for (uint256 i = 0; i < voterNFTBalance; i++) {
                uint256 tokenId = zeeCardsNFT.tokenOfOwnerByIndex(msg.sender, i);
                if (proposal.voters[tokenId] == false) {
                    numVotes++;
                    proposal.voters[tokenId] = true;
                }
            }
            require(numVotes > 0, "ALREADY_VOTED");

            if (vote == Vote.YAY) {
                proposal.yayVotes += numVotes;
            } else {
                proposal.nayVotes += numVotes;
            }
        }

        // Create a modifier which only allows a function to be
        // called if the given proposals' deadline HAS been exceeded
        // and if the proposal has not yet been executed
        modifier inactiveProposalOnly(uint256 proposalIndex) {
            require(
                proposals[proposalIndex].deadline <= block.timestamp,
                "DEADLINE_NOT_EXCEEDED"
            );
            require(
                proposals[proposalIndex].executed == false,
                "PROPOSAL_ALREADY_EXECUTED"
            );
            _;
        }

        /// @dev executeProposal allows any ZeeCardsNFT holder to execute a proposal after it's deadline has been exceeded
        /// @param proposalIndex - the index of the proposal to execute in the proposals array
        function executeProposal(uint256 proposalIndex)
            external
            nftHolderOnly
            inactiveProposalOnly(proposalIndex)
        {
            Proposal storage proposal = proposals[proposalIndex];

            // If the proposal has more YAY votes than NAY votes
            // purchase the NFT from the FakeNFTMarketplace
            if (proposal.yayVotes > proposal.nayVotes) {
                uint256 nftPrice = nftMarketplace.getPrice();
                require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
                nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
            }
            proposal.executed = true;
        }

        /// @dev withdrawEther allows the contract owner (deployer) to withdraw the ETH from the contract
        function withdrawEther() external onlyOwner {
            payable(owner()).transfer(address(this).balance);
        }

        // The following two functions allow the contract to accept ETH deposits
        // directly from a wallet without calling a function
        receive() external payable {}

        fallback() external payable {}










}