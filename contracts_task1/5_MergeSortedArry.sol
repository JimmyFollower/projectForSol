// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

// 合并两个有序数组 (Merge Sorted Array)
// - 题目描述：将两个有序数组合并为一个有序数组。
contract MergeSortedArray {
    function merge(
        uint256[] calldata arr1,
        uint256[] calldata arr2
    ) external pure returns (uint256[] memory) {
        uint256 length1 = arr1.length;
        uint256 length2 = arr2.length;
        uint256 totalLength = length1 + length2;

        // 预分配结果数组
        uint256[] memory result = new uint256[](totalLength);

        uint256 i = 0; // arr1 指针
        uint256 j = 0; // arr2 指针
        uint256 k = 0; // result 指针

        // 合并两个有序数组
        while (i < length1 && j < length2) {
            if (arr1[i] <= arr2[j]) {
                result[k] = arr1[i];
                i++;
            } else {
                result[k] = arr2[j];
                j++;
            }
            k++;
        }

        // 处理剩余元素
        while (i < length1) {
            result[k] = arr1[i];
            i++;
            k++;
        }

        while (j < length2) {
            result[k] = arr2[j];
            j++;
            k++;
        }

        return result;
    }
}