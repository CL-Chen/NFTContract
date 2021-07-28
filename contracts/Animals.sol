// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

interface Garage {
    function price() external returns (uint256);

    function purchase() external payable;
}

contract Animals is ERC721PresetMinterPauserAutoId, Garage {
    address public developer;
    uint256 public constant override price = 1e18;
    mapping(uint256 => uint256) private resalePrice;
    mapping(uint256 => string) private metaDataTracker;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721PresetMinterPauserAutoId(name, symbol, baseTokenURI) {
        _setupRole(MINTER_ROLE, address(this));
        developer = msg.sender;
        _privateTracker.increment();
    }

    function mint(address to) public virtual override {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC721PresetMinterPauserAutoId: must have minter role to mint"
        );

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(to, _tokenIdTracker.current());

        //***Added new function to handle IPFS metaData Mapping
        mapTokenIdToIPFS();
        _privateTracker.increment();
        _tokenIdTracker.increment();
    }

    //*** declared a seperate set of _tokenIdTracker because this child contract cannot access
    //*** the parent contract's (i.e. ERC721PresetMinterPauserAutoId) _tokenIdTracker
    //*** as it was declared as a private counter
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _privateTracker;

    function mapTokenIdToIPFS() private {
        uint256 currentTokenId = totalSupply() - 1;
        metaDataTracker[currentTokenId] = uint2str(random() % 25);
    }

    function purchase() public payable override {
        require(msg.value >= price);
        // Send ethers to developer
        (bool success, ) = developer.call{value: msg.value}("");
        require(success);

        // Mint NFT (using external call)
        this.mint(msg.sender);
        _privateTracker.increment();
    }

    function purchaseMultipleTokens(uint256 quantity) public payable {
        require(msg.value >= quantity * price);
        // Send ethers to developer
        (bool success, ) = developer.call{value: msg.value}("");
        require(success);

        // Mint NFT (using external call)
        for (uint256 i = 0; i < quantity; i++) {
            this.mint(msg.sender);
        }
        _privateTracker.increment();
    }

    function getResalePrice(uint256 tokenId) public view returns (uint256) {
        uint256 formattedResalePrice = resalePrice[tokenId];
        return formattedResalePrice;
    }

    function facilitateSale(uint256 tokenId) public payable {
        require(msg.value >= getResalePrice(tokenId));

        address ownerAdd = ownerOf(tokenId);
        (bool success, ) = ownerAdd.call{value: (msg.value)}("");
        require(success);

        this.transferFrom(ownerAdd, msg.sender, tokenId);

        _privateTracker.increment();
    }

    function setResalePrice(uint256 setPrice, uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId));
        approve(address(this), tokenId);

        //set price in wei, i.e. 1e18 * etherPrice
        resalePrice[tokenId] = setPrice;
        _privateTracker.increment();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        string memory metaNum = metaDataTracker[tokenId];

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, metaNum))
                : "";
    }

    function random() private view returns (uint256) {
        return
            uint256(
                (
                    keccak256(
                        abi.encodePacked(
                            ((block.timestamp / 1000) *
                                block.difficulty *
                                10 *
                                block.number) /
                                12 +
                                _tokenIdTracker.current() *
                                _privateTracker.current()
                        )
                    )
                )
            );
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }

        return string(bstr);
    }
}
