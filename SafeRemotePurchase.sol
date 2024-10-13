// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract SafeRemotePurchase{
    /*State Variables*/
    uint256 value; 
    address payable seller;
    address  payable buyer; 
    enum State { Created, Locked, Release, Inactive }
    State public state;

    /*error*/
    error notInTheRightState();
    error notSeller();
    error notBuyer(); 
    error refundUnsuccesful(); 

    /*Events*/
    event Aborted();
    event PurchaseConfirmed(); 
    event ItemRecieved(); 
    event SellerRefunded(); 

    /*Modifiers*/
    modifier inState(State _state){
        if(state != _state){
            revert notInTheRightState();
        }
        _;
    }

    modifier onlyBuyer(){
        require(msg.sender == buyer, notBuyer()); 
        _;
    }

    modifier onlySeller(){
        require(msg.sender == seller, notSeller()); 
        _;
    }

    /*Constructor*/
    constructor() payable {
        require(msg.value%2 == 0, "value not even");
        seller = payable(msg.sender);
        value = msg.value/2;
    }

    /*Functions*/
    function abort() public inState(State.Created) onlySeller{
        emit Aborted();
        state = State.Inactive;
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, refundUnsuccesful());
    } 

    function confirmPurchase() public payable inState(State.Created){
        require(msg.value == 2*value, "msg.value needs to be twice of value");
        state = State.Locked;
        buyer = payable(msg.sender);
    }

    function confirmRecieve() public onlyBuyer inState(State.Locked){
        state = State.Release; 
        (bool success, ) = payable(msg.sender).call{value: value}("");
        require(success, "Recieve Unsuccessful");
    }

    function refundSeller() public onlySeller inState(State.Release){
        state = State.Inactive;
        (bool success, ) = payable(msg.sender).call{value: value*3}("");
        require(success, refundUnsuccesful());
    }
}