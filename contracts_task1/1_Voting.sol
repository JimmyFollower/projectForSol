
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// 一个mapping来存储候选人的得票数,
// 一个vote函数，允许用户投票给某个候选人,
// 一个getVotes函数，返回某个候选人的得票数,
// 一个resetVotes函数，重置所有候选人的得票数
contract Voting {
    mapping(address => uint256) public candidateVotes;
    address[] public candidateList;
    
    // 检查地址是否已是候选人
    mapping(address => bool) public isCandidate;

    // 添加候选人（仅允许合约部署者操作）
    function addCandidate(address _candidate) external {
        require(!isCandidate[_candidate], "Already a candidate");
        candidateList.push(_candidate);
        isCandidate[_candidate] = true;
    }

    // 投票
    function vote(address _candidate) external {
        require(isCandidate[_candidate], "Not a valid candidate");
        candidateVotes[_candidate] += 1;
    }

    // 查询得票数
    function getVotes(address _candidate) external view returns (uint256) {
        return candidateVotes[_candidate];
    }

    // 重置所有候选人得票数
    function resetVotes() external {
        for (uint256 i = 0; i < candidateList.length; i++) {
            candidateVotes[candidateList[i]] = 0;
        }
    }
}
