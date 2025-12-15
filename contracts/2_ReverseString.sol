// SPDX-License-Identifier: MIT
pragma solidity  ^0.8;

contract ReverseString{
    function reverse (string memory str) public  pure returns(string memory ) {
        bytes memory strBytes=bytes(str);
        uint256 length=strBytes.length;

        if(length<=1) return  str;
        bytes memory res=new bytes(length);
        for (uint256 i=0;i<length;i++){
            res[i]=strBytes[length-1-i];
        }
        return  string(res);
    }
}