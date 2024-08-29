// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import "@openzeppelin-contracts/token/ERC20/ERC20.sol";


library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

contract Dex is ERC20{
    IERC20 tokenX;
    IERC20 tokenY;
    
    uint256 totalLp;

    constructor(address _tokenX, address _tokenY) ERC20("LP", "LP"){
        tokenX = IERC20(_tokenX);
        tokenY = IERC20(_tokenY);
    }

    function addLiquidity(uint256 currentX, uint256 currentY, uint256 minLp) public returns(uint256 amountLp) {
        require(tokenX.allowance(msg.sender, address(this)) >= currentX || tokenY.allowance(msg.sender, address(this)) >= currentY, "ERC20: insufficient allowance");
        require(tokenX.balanceOf(msg.sender) >= currentX || tokenY.balanceOf(msg.sender) >= currentY, "ERC20: transfer amount exceeds balance");
        require(currentX > 0 && currentY > 0, "can not zero your token amount.");

        uint256 totalX = tokenX.balanceOf(address(this));
        uint256 totalY = tokenY.balanceOf(address(this));


        if(totalLp == 0){
            amountLp = Math.sqrt(currentX * currentY);
        }
        else {
            amountLp = Math.min((currentX * totalLp / totalX), (currentY * totalLp / totalY));
        }

        require(amountLp > minLp, "must be higher this LP.");
        tokenX.transferFrom(msg.sender, address(this), currentX);
        tokenY.transferFrom(msg.sender, address(this), currentY);

        _mint(msg.sender, amountLp);

        totalLp += amountLp;
    }


    function removeLiquidity(uint256 amountLp, uint256 currentX, uint256 currentY) public returns (uint256 amountX, uint256 amountY) {
        uint256 totalX = tokenX.balanceOf(address(this));
        uint256 totalY = tokenY.balanceOf(address(this));

        if(amountLp == totalLp) {
            amountX = amountLp;
            amountY = amountLp;
        } 
        else {
            amountX = amountLp * totalX / totalLp;
            amountY = amountLp * totalY / totalLp;
        }

        require(amountX * amountY * amountLp >= currentX * currentY * amountLp, "imbalanced token");
        require(amountX > 0 && amountY > 0, "must be higher than zero");

        tokenX.transfer(msg.sender, amountX);
        tokenY.transfer(msg.sender, amountY);
        
        _burn(msg.sender, amountLp);
        totalLp -= amountLp;
    }

    function swap(uint256 currentX, uint256 currentY, uint256 minAmount) public returns (uint256 swapAmount) {
        require(currentX == 0 || currentY == 0);

        uint256 totalX = tokenX.balanceOf(address(this));
        uint256 totalY = tokenY.balanceOf(address(this));
        uint256 k = totalX * totalY;

        uint256 destToken = k / (currentX > 0 ? (totalX + currentX) : (totalY + currentY));
        swapAmount = ((currentX > 0 ? totalY : totalX) - destToken) * 999 / 1000;

        require(swapAmount >= minAmount);

        if(currentX > 0){
            tokenX.transferFrom(msg.sender, address(this), currentX);
            tokenY.transfer(msg.sender, swapAmount);
        }
        else {
            tokenY.transferFrom(msg.sender, address(this), currentY);
            tokenX.transfer(msg.sender, swapAmount);
        }
    }
}