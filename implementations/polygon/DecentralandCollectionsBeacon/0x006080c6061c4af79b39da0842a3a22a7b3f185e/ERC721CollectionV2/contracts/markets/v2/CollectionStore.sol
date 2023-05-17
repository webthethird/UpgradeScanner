// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../../interfaces/IERC20.sol";
import "../../interfaces/IERC721CollectionV2.sol";
import "../../commons/OwnableInitializable.sol";
import "../../commons/NativeMetaTransaction.sol";

contract CollectionStore is OwnableInitializable, NativeMetaTransaction {
    using SafeMath for uint256;


    struct ItemToBuy {
        IERC721CollectionV2 collection;
        uint256[] ids;
        uint256[] prices;
        address[] beneficiaries;
    }

    uint256 constant public BASE_FEE = 1000000;
    IERC20 public acceptedToken;
    uint256 public fee;
    address public feeOwner;

    event Bought(ItemToBuy[] _itemsToBuy);
    event SetFee(uint256 _oldFee, uint256 _newFee);
    event SetFeeOwner(address indexed _oldFeeOwner, address indexed _newFeeOwner);

    /**
    * @notice Constructor of the contract.
    * @param _acceptedToken - Address of the ERC20 token accepted
    * @param _feeOwner - address where fees will be transferred
    * @param _fee - fee to charge for each sale
    */
    constructor(address _owner, IERC20 _acceptedToken, address _feeOwner, uint256 _fee) {
        // EIP712 init
        _initializeEIP712('Decentraland Collection Store', '1');
        // Ownable init
        _initOwnable();

        acceptedToken = _acceptedToken;
        feeOwner = _feeOwner;
        setFee(_fee);

        transferOwnership(_owner);
    }

    /**
    * @notice Buy collection's items.
    * @dev There is a maximum amount of NFTs that can be issued per call by the block's limit.
    * @param _itemsToBuy - items to buy
    */
    function buy(ItemToBuy[] memory _itemsToBuy) external {
        uint256 totalFee = 0;
        address sender = _msgSender();

        for (uint256 i = 0; i < _itemsToBuy.length; i++) {
            ItemToBuy memory itemToBuy = _itemsToBuy[i];
            IERC721CollectionV2 collection = itemToBuy.collection;
            uint256 amountOfItems = itemToBuy.ids.length;

            require(amountOfItems == itemToBuy.prices.length, "CollectionStore#buy: LENGTH_MISMATCH");

            for (uint256 j = 0; j < amountOfItems; j++) {
                uint256 itemId = itemToBuy.ids[j];
                uint256 price = itemToBuy.prices[j];

                (uint256 itemPrice, address itemBeneficiary) = getItemBuyData(collection, itemId);
                require(price == itemPrice, "CollectionStore#buy: ITEM_PRICE_MISMATCH");

                if (itemPrice > 0) {
                    // Calculate sale share
                    uint256 saleShareAmount = itemPrice.mul(fee).div(BASE_FEE);
                    totalFee = totalFee.add(saleShareAmount);

                    // Transfer sale amount to the item beneficiary
                    require(
                        acceptedToken.transferFrom(sender, itemBeneficiary, itemPrice.sub(saleShareAmount)),
                        "CollectionStore#buy: TRANSFER_PRICE_FAILED"
                    );
                }
            }

            // Mint Token
            collection.issueTokens(itemToBuy.beneficiaries, itemToBuy.ids);
        }

        if (totalFee > 0) {
            // Transfer share amount for fees owner
            require(
                acceptedToken.transferFrom(sender, feeOwner, totalFee),
                "CollectionStore#buy: TRANSFER_FEES_FAILED"
            );
        }
        emit Bought(_itemsToBuy);
    }

    /**
     * @notice Get item's price and beneficiary
     * @param _collection - collection address
     * @param _itemId - item id
     * @return uint256 of the item's price
     * @return address of the item's beneficiary
     */
    function getItemBuyData(IERC721CollectionV2 _collection, uint256 _itemId) public view returns (uint256, address) {
      (,,,uint256 price, address beneficiary,,) = _collection.items(_itemId);
       return (price, beneficiary);
    }

    // Owner functions

    /**
     * @notice Sets the fee of the contract that's charged to the seller on each sale
     * @param _newFee - Fee from 0 to 999,999
     */
    function setFee(uint256 _newFee) public onlyOwner {
        require(_newFee < BASE_FEE, "CollectionStore#setFee: FEE_SHOULD_BE_LOWER_THAN_BASE_FEE");
        require(_newFee != fee, "CollectionStore#setFee: SAME_FEE");

        emit SetFee(fee, _newFee);
        fee = _newFee;
    }

    /**
     * @notice Set a new fee owner.
    * @param _newFeeOwner - Address of the new fee owner
     */
    function setFeeOwner(address _newFeeOwner) external onlyOwner {
        require(_newFeeOwner != address(0), "CollectionStore#setFeeOwner: INVALID_ADDRESS");
        require(_newFeeOwner != feeOwner, "CollectionStore#setFeeOwner: SAME_FEE_OWNER");

        emit SetFeeOwner(feeOwner, _newFeeOwner);
        feeOwner = _newFeeOwner;
    }
}
