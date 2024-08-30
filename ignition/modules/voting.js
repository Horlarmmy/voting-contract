const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("VotingModule", (m) => {

  // Define parameters for TokenizedVoting contract deployment
  const electionName = m.getParameter("electionName", "Election 2024");
  const categoryNames = m.getParameter("categoryNames", ["Best Developer", "Best Designer"]);
  const candidates = m.getParameter("candidates", [["Alice", "Bob"], ["Charlie", "Dave"]]);

  // Deploy the TokenizedVoting contract with parameters
  const tokenizedVoting = m.contract("TokenizedVoting", [electionName, categoryNames, candidates]);

  m.call(tokenizedVoting, "startVoting", []);

  return { tokenizedVoting };
});