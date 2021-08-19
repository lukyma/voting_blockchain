pragma solidity >=0.4.22 < 0.6.0;
pragma experimental ABIEncoderV2;

/// @title Voting with delegation.
contract Ballot {
    // This declares a new complex type which will
    // be used for variables later.
    // It will represent a single voter.
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted proposal
        string name; //nome do eleitor ***
    }
    
    //Votação foi finalizada
    bool private endVoting = false;

    // This is a type for a single proposal.
    struct Proposal {
        string name;
        uint voteCount; // number of accumulated votes
    }

    address public chairperson;

    // This declares a state variable that
    // stores a `Voter` struct for each possible address.
    mapping(address => Voter) private voters;
    
    //Lista de endereços adicionados para recuperar os eleitores posteriormente
    address[] public addressVoters;

    // A dynamically-sized array of `Proposal` structs.
    Proposal[] private proposals;

    /// Create a new ballot to choose one of `proposalNames`.
    constructor() public {
        string[3] memory proposalNames = ["Proposta 1","Proposta 2", "Proposta 3"];
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        voters[chairperson].name = "Presidente da Eleição";
        addressVoters.push(chairperson);

        // For each of the provided proposal names,
        // create a new proposal object and add it
        // to the end of the array.
        for (uint i = 0; i < proposalNames.length; i++) {
            // `Proposal({...})` creates a temporary
            // Proposal object and `proposals.push(...)`
            // appends it to the end of `proposals`.
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    // Give `voter` the right to vote on this ballot.
    // May only be called by `chairperson`.
    function giveRightToVote(address voter, string memory name) public {
        // If the first argument of `require` evaluates
        // to `false`, execution terminates and all
        // changes to the state and to Ether balances
        // are reverted.
        // This used to consume all gas in old EVM versions, but
        // not anymore.
        // It is often a good idea to use `require` to check if
        // functions are called correctly.
        // As a second argument, you can also provide an
        // explanation about what went wrong.
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        
        //Votação já foi finalizada
        require(!endVoting, "Voting has already ended.");
        
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
        voters[voter].name = name;
        addressVoters.push(voter);
    }
    

    /// Delegate your vote to the voter `to`.
    function delegate(address to) public {
        // assigns reference
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        
        require(to != msg.sender, "Self-delegation is disallowed.");
        
        //Permite delegação apenas para pessoas com direito a voto ***
        Voter storage receiver = voters[to];
        require(receiver.weight != 0, "The person delegate has no voting rights.");
        
        //Votação já foi finalizada
        require(!endVoting, "Voting has already ended.");
        

        // Forward the delegation as long as
        // `to` also delegated.
        // In general, such loops are very dangerous,
        // because if they run too long, they might
        // need more gas than is available in a block.
        // In this case, the delegation will not be executed,
        // but in other situations, such loops might
        // cause a contract to get "stuck" completely.
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }

        // Since `sender` is a reference, this
        // modifies `voters[msg.sender].voted`
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }

    /// Give your vote (including votes delegated to you)
    /// to proposal `proposals[proposal].name`.
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        
        //Votação já foi finalizada
        require(!endVoting, "Voting has already ended.");
        
        sender.voted = true;
        sender.vote = proposal;

        // If `proposal` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount += sender.weight;
    }

    /// @dev Computes the winning proposal taking all
    /// previous votes into account.
    function winningProposal() public view
            returns (uint winningProposal_)
    {
        //Votação ainda não foi finalizada
        require(endVoting, "Voting is not over.");
        
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    // Calls winningProposal() function to get the index
    // of the winner contained in the proposals array and then
    // returns the name of the winner
    function winnerName() public view
            returns (string memory winnerName_)
    {
        //Votação ainda não foi finalizada
        require(endVoting, "Voting is not over.");
        
        winnerName_ = proposals[winningProposal()].name;
    }
    
    function getProposalsCount() public view 
            returns (uint count) 
    {
        count = proposals.length;
    }
    
    function getProposal(uint index) public view
            returns (string memory name, uint voteCount)
    {
        if(endVoting){
           voteCount = proposals[index].voteCount; 
        }
        else{
            voteCount = 0;
        }
        name = proposals[index].name;
    }
    
    function getAllProposal() public view returns (Proposal[] memory)
    {
        return proposals;
    }
    
    
    //Nome do eleitor
    function getVoterName(address voter) public view returns (string memory)
    {
        return voters[voter].name;
    }       
    
    //Eleitor já votou?
    function getVoterVoteStatus(address voter) public view returns (bool)
    {
        return voters[voter].voted;
    }   
    
    //Eleitor delegou o voto?
    function getVoterDelegateStatus(address voter) public view returns (bool)
    {
        return (voters[voter].delegate != address(0));
    }
    
    //Lista de Eleitores
    function getVoters() public view returns (Voter[] memory)
    {
        Voter[] memory voters_ = new Voter[](addressVoters.length);
        
        for (uint i = 0; i < addressVoters.length; i++) {
            Voter memory voter = voters[addressVoters[i]];
            voters_[i] = voter;
        }
        
        return voters_;
    }
    
    function getVotingStatus() public view returns (uint status)
    {
        if (endVoting)
            return 1;
        else
            return 0;
    }
    
    
    //inclusão de propostas para votação
    function addProposal(string memory proposalName) public 
    {
        //Candidatos podem ser adicionados apenas pelo presidente.
        require(
            msg.sender == chairperson,
            "Only the chair can add proposals."
        );
        
        //Candidatos não podem ser adicionados após finalizar a votação
        require(!endVoting, "Voting has already ended.");
        
        proposals.push(Proposal({
                name: proposalName,
                voteCount: 0
            }));
    }
    
        
    //Finaliza votação
    function finishVoting() public
    {
        //Votação pode ser finalizada apenas pelo presidente.
        require(
            msg.sender == chairperson,
            "Only the chair can add proposals."
        );
        
        //Votação já foi finalizada
        require(!endVoting, "Voting has already ended.");
        
        endVoting = true;
    }
    
    //Resultado da votação
    function getVotingResult () public view returns (Proposal[] memory)
    {
        //Votação ainda não foi finalizada
        require(endVoting, "Voting is not over.");
        
        return proposals;
    }
    
}
