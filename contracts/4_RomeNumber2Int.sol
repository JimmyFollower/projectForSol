// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

// 用 solidity 实现罗马数字转数整数
// - 1 <= s.length <= 15
// - s 仅含字符 ('I', 'V', 'X', 'L', 'C', 'D', 'M')
// - 题目数据保证 s 是一个有效的罗马数字，且表示整数在范围 [1, 3999] 内
// - 题目所给测试用例皆符合罗马数字书写规则，不会出现跨位等情况。
// - IL 和 IM 这样的例子并不符合题目要求，49 应该写作 XLIX，999 应该写作 CMXCIX 。
// 字符          数值
// I             1
// V             5
// X             10
// L             50
// C             100
// D             500
// M             1000


contract RomanNumber2Tint{
    mapping  (bytes1 =>uint256) private romanMap;
    constructor(){ 
        romanMap["I"]=1;
        romanMap["V"]=5;
        romanMap["X"]=10;
        romanMap["L"]=50;
        romanMap["C"]=100;
        romanMap["D"]=500;
        romanMap["M"]=1000;
    
    }

    function romanToInt(string memory roman)public  view  returns (uint256){
        bytes memory romanBytes=bytes(roman);
        uint256 length=romanBytes.length;
        if(length==0) revert("Empty string");
        uint256 res;
        uint256 prevValue;
        for (uint256 i=length;i>0;i--){
            bytes1 currentChar=romanBytes[i-1];
            uint256 currentValue= romanMap[currentChar];
            if(currentValue<prevValue){
                res-=currentValue;
            }else{
                res+=currentValue;
            }
            prevValue=currentValue;
        }
        return  res;
    }
}