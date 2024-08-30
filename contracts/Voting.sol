// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function mint(address account, uint256 amount) external;
}

contract VotingToken is IERC20 {
    string public constant name = "VotingToken";
    string public constant symbol = "VTK";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        return true;
    }

    function mint(address account, uint256 amount) public override onlyOwner {
        totalSupply += amount;
        balances[account] += amount;
    }
}

contract TokenizedVoting {
    // Election details
    string public electionName;
    string[] public categoryNames;
    mapping(string => string[]) public candidates;
    address private electionOfficial;
    uint256 tokenAmount = 10;
    uint256 public registeredVoter = 0;
    uint256 public votedUser = 0;

    // Voting tokens
    VotingToken public votingToken;
    mapping(address => uint256) public votingTokens;

    // Voting records
    mapping(string => mapping(string => uint256)) public votes;
    mapping(address => bool) public hasVoted;

    // Voting status
    bool public votingStarted;
    bool public votingEnded;

    //Structs
    struct CandidateList {
        string candidate;
        string category;
    }

    struct VotingResult {
        string candidate;
        string category;
        uint256 votes;
    }

    // Events
    event VoteCast(address indexed voter, string[] candidates);

    modifier onlyOfficial() {
        require(msg.sender == electionOfficial, "Only election official can perform this action");
        _;
    }

    // Constructor to initialize election details
    constructor(
        string memory _electionName,
        string[] memory _categoryNames,
        string[][] memory _candidates
    ) {
        electionName = _electionName;
        categoryNames = _categoryNames;
        for (uint256 i = 0; i < _categoryNames.length; i++) {
            candidates[_categoryNames[i]] = _candidates[i];
        }
        votingToken = new VotingToken();
        electionOfficial = msg.sender;
    }

    // Function to register voters and allocate voting tokens
    function registerVoter() public {
        require(votingTokens[msg.sender] == 0, "Voter already registered");
        votingToken.mint(msg.sender, tokenAmount);
        votingTokens[msg.sender] = tokenAmount;
        hasVoted[msg.sender] = false;
        registeredVoter +=1;
    }

    // Function to start voting
    function startVoting() public onlyOfficial {
        require(!votingStarted, "Voting already started");
        require(!votingEnded, "Voting already ended");
        votingStarted = true;
    }

    // Function to end voting
    function endVoting() public onlyOfficial {
        require(votingStarted, "Voting not started yet");
        require(!votingEnded, "Voting already ended");
        votingEnded = true;
    }

    // Function to cast votes for multiple choices at once
    function vote(string[] memory _candidates) public {
        require(votingStarted, "Voting has not started yet");
        require(!hasVoted[msg.sender], "You have already voted");
        require(!votingEnded, "Voting has ended");
        require(_candidates.length == categoryNames.length, "Mismatched categories and candidates");
        require(votingTokens[msg.sender] >= _candidates.length, "You are not registered to vote");

        for (uint256 i = 0; i < _candidates.length; i++) {
            string memory category = categoryNames[i];
            string memory candidate = _candidates[i];
            require(isValidCandidate(category, candidate), "Invalid candidate");
            votes[category][candidate]++;
            votingTokens[msg.sender]--;
        }
        hasVoted[msg.sender] =true;
        votedUser += 1;
        emit VoteCast(msg.sender, _candidates);

    }

    // Internal function to check if a candidate is valid
    function isValidCandidate(string memory category, string memory candidate) internal view returns (bool) {
        string[] memory candidateList = candidates[category];
        for (uint256 i = 0; i < candidateList.length; i++) {
            if (keccak256(abi.encodePacked(candidateList[i])) == keccak256(abi.encodePacked(candidate))) {
                return true;
            }
        }
        return false;
    }

    //Function to get all candidates
    function getAllCandidates() public view returns (CandidateList[] memory) {
        uint256 totalCandidates = 0;
        for (uint256 i = 0; i < categoryNames.length; i++) {
            totalCandidates += candidates[categoryNames[i]].length;
        }
        CandidateList[] memory allCandidates = new CandidateList[](totalCandidates);
        uint256 index = 0;
        for (uint256 i = 0; i < categoryNames.length; i++) {
            string memory category = categoryNames[i];
            string[] memory categoryCandidates = candidates[category];
            for (uint256 j = 0; j < categoryCandidates.length; j++) {
                allCandidates[index] = CandidateList(categoryCandidates[j], category);
                index++;
            }
        }
        return allCandidates;
    }

    //Function to get votes for all candidates
    function getAllVotes() public view returns (VotingResult[] memory) {
        uint256 totalCandidates = 0;
        for (uint256 i = 0; i < categoryNames.length; i++) {
            totalCandidates += candidates[categoryNames[i]].length;
        }
        VotingResult[] memory allVotes = new VotingResult[](totalCandidates);
        uint256 index = 0;
        for (uint256 i = 0; i < categoryNames.length; i++) {
            string memory category = categoryNames[i];
            string[] memory categoryCandidates = candidates[category];
            for (uint256 j = 0; j < categoryCandidates.length; j++) {
                string memory candidate = categoryCandidates[j];
                uint256 voteCount = votes[category][candidate];
                allVotes[index] = VotingResult(candidate, category, voteCount);
                index++;
            }
        }
        return allVotes;
    }           
}
