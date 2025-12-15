// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract BinarySearch{
    function search(uint256 []calldata arr, uint target) public  pure returns (uint256 res){
        uint256 left=0;
        uint256 right=arr.length;

        while (left<right){
            uint256 mid=left+(right-left)/2;
            if(arr[mid]==target) res=mid;
            else  if(arr[mid]<target){
                left=mid+1;
            }else{
                right=mid;
            }
        }
        
        
    }
}