pragma solidity ^0.4.24;

import "./AbstractHotel.sol";

/**
 * @title Hotel, contract for a Hotel registered in the WT network
 * @dev A contract that represents a hotel in the WT network. Inherits
 * from WT's 'AbstractHotel'.
 */
contract Hotel is AbstractHotel {

  bytes32 public contractType = bytes32("hotel");

  enum BookingRequestStatus {PENDING,ACCEPTED,REJECTED,CANCELED}

  struct BookingRequest{
    address sender;
    string encryptedData;
    uint256[] cancellationFrom;
    uint256[] cancellationTo;
    uint8[] cancellationAmount;
    uint256 total;
    BookingRequestStatus status;
  }
  // List of all booking requests
  BookingRequest[] bookingRequests;


  event newBookingRequest(address _sender, string _encryptedData, uint256[] _cancellationFrom, uint256[] _cancellationTo, uint8[] _cancellationAmount, uint256 _total, uint256 _id );
  event BookingAccepted(address _sender, uint256 id);
  event BookingRejected(address _sender, uint256 id);

  modifier onlyManager {
        require(msg.sender == manager);
        _;
    }

  /**
   * @dev Constructor.
   * @param _manager address of hotel owner
   * @param _dataUri pointer to hotel data
   * @param _index originating WTIndex address
   */
  constructor (address _manager, string _dataUri, address _index) public {
    require(_manager != address(0));
    require(_index != address(0));
    require(bytes(_dataUri).length != 0);
    manager = _manager;
    index = _index;
    dataUri = _dataUri;
    created = block.number;
  }

  function _editInfoImpl(string _dataUri) internal {
    require(bytes(_dataUri).length != 0);
    dataUri = _dataUri;
  }

  function _destroyImpl() internal {
    selfdestruct(manager);
  }

  function _changeManagerImpl(address _newManager) internal {
    require(_newManager != address(0));
    manager = _newManager;
  }
  /**
   * @dev Accepts booking request.
   * @param id The id of the accepted booking request
   */
  function acceptBooking(uint256 id) public onlyManager{
    require(bookingRequests[id].status == BookingRequestStatus.PENDING);
    bookingRequests[id].status = BookingRequestStatus.ACCEPTED;
    emit BookingAccepted(bookingRequests[id].sender, id);
  }
  /**
   * @dev Rejects booking request.
   * @param id The id of the rejected booking request
   */
  function rejectBooking(uint256 id) public onlyManager{
    require(bookingRequests[id].status == BookingRequestStatus.PENDING);
    bookingRequests[id].status = BookingRequestStatus.REJECTED;
    emit BookingRejected(bookingRequests[id].sender, id);
  }

  function cancelBooking(uint256 id) public {
    require(bookingRequests[id].sender == msg.sender && (bookingRequests[id].status == BookingRequestStatus.ACCEPTED || bookingRequests[id].status == BookingRequestStatus.PENDING));
    for(uint i=0;i<bookingRequests[id].cancellationTo.length;i++){
      if(now >= bookingRequests[id].cancellationFrom[i] && now <= bookingRequests[id].cancellationTo[i]){
        // Refund user's money
        bookingRequests[id].sender.transfer(bookingRequests[id].cancellationAmount[i]*bookingRequests[id].total/100);
        bookingRequests[id].status = BookingRequestStatus.CANCELED;
      }
    }
  }

  /**
   * @dev Adds booking request.
   * @param encrypedData encrypted information about the booking
   * @param cancellationFrom list containing start dates of cancellation policies
   * @param cancellationTo list containing end dates of cancellation policies
   * @param cancellationAmount list containing amounts of cancellation policies
   */
  function book(string encrypedData, uint256[] cancellationFrom, uint256[] cancellationTo, uint8[] cancellationAmount) public payable {
    bookingRequests.push(BookingRequest(msg.sender, encrypedData, cancellationFrom, cancellationTo, cancellationAmount, msg.value, BookingRequestStatus.PENDING));
    emit newBookingRequest(msg.sender, encrypedData, cancellationFrom, cancellationTo, cancellationAmount, msg.value, bookingRequests.length-1);
  }

}
