// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
// 用 solidity 实现整数转罗马数字
// - 范围：1 <= num <= 3999
// 符号    值
// I       1
// V       5
// X       10
// L       50
// C       100
// D       500
// M       1000
contract Number2RomeNumber{
    struct RomanSymbol{
        uint256 value;
        string symbol;
    }

    RomanSymbol[] private  romanSymbols;
    constructor(){
        romanSymbols.push(RomanSymbol(1000, "M"));
        romanSymbols.push(RomanSymbol(900, "CM"));
        romanSymbols.push(RomanSymbol(500, "D"));
        romanSymbols.push(RomanSymbol(400, "CD"));
        romanSymbols.push(RomanSymbol(100, "C"));
        romanSymbols.push(RomanSymbol(90, "XC"));
        romanSymbols.push(RomanSymbol(50, "L"));
        romanSymbols.push(RomanSymbol(40, "XL"));
        romanSymbols.push(RomanSymbol(10, "X"));
        romanSymbols.push(RomanSymbol(9, "IX"));
        romanSymbols.push(RomanSymbol(5, "V"));
        romanSymbols.push(RomanSymbol(4, "IV"));
        romanSymbols.push(RomanSymbol(1, "I"));
    }

    function intToRoman(uint256 num) public  view  returns (string memory){
        require(num>=1&&num<=3999,"Number of range (1-39999)");

        string memory result;
        uint256 remaining =num;

        for(uint256 i=0;i<romanSymbols.length;i++){
            RomanSymbol memory symbol=romanSymbols[i];
            while (remaining>=symbol.value){
                result=string.concat(result,symbol.symbol);
                remaining-=symbol.value;
            }
        }
        return  result;
    }

}