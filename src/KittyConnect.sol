// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {KittyBridge} from "./KittyBridge.sol";

/**
 * @title KittyConnect
 * @author Shikhar Agarwal
 * @notice This contract allows users to buy a cute cat from our branches and mint NFT for buying a cat
 * The NFT will be used to track the cat info and all related data for a particular cat corresponding to their token ids
 */
contract KittyConnect is ERC721 {
    struct CatInfo {
        string catName;
        string breed;
        string image;
        uint256 dob;
        address[] prevOwner;
        address shopPartner;
        uint256 idx;
    }

    // Storage Variables
    uint256 private kittyTokenCounter;
    address private immutable i_kittyConnectOwner;
    mapping(address => bool) private s_isKittyShop;

    /**
     * Son las address de las shops desplegadas.
     * Se añaden en:
     * vulnerabilidad potencial por ser array.
     * La variable es privada pero ¿se puede afectar de alguna forma?
     */
    address[] private s_kittyShops;
    mapping(address user => uint256[]) private s_ownerToCatsTokenId;
    mapping(uint256 tokenId => CatInfo) private s_catInfo;
    KittyBridge private immutable i_kittyBridge;

    // Events
    event ShopPartnerAdded(address partner);
    event CatMinted(uint256 tokenId, string catIpfsHash);
    event TokensRedeemedForVetVisit(uint256 tokenId, uint256 amount, string remarks);
    event CatTransferredToNewOwner(address prevOwner, address newOwner, uint256 tokenId);
    event NFTBridgeRequestSent(uint256 sourceChainId, uint64 destChainSelector, address destBridge, uint256 tokenId);
    event NFTBridged(uint256 chainId, uint256 tokenId);

    // Modifiers
    /**
     * Este es el owner del contrato
     * No se puede trasnferir el ownership -> esto debe ser a LOW o incluso una HIGH.
     */
    modifier onlyKittyConnectOwner() {
        require(msg.sender == i_kittyConnectOwner, "KittyConnect__NotKittyConnectOwner");
        _;
    }

    modifier onlyShopPartner() {
        require(s_isKittyShop[msg.sender], "KittyConnect__NotAPartner");
        _;
    }

    /*
     * KittiBridge posiblemente sea el contrato.
     * Se facilita en el constructor.
     */
    modifier onlyKittyBridge() {
        require(msg.sender == address(i_kittyBridge), "KittyConnect__NotKittyBridge");
        _;
    }

    // Constructor
    constructor(address[] memory initShops, address router, address link) ERC721("KittyConnect", "KC") {
        for (uint256 i = 0; i < initShops.length; i++) {
            s_kittyShops.push(initShops[i]);
            s_isKittyShop[initShops[i]] = true;
        }

        i_kittyConnectOwner = msg.sender;
        i_kittyBridge = new KittyBridge(router, link, msg.sender);
    }

    // Functions

    /////////////////////////////
    // EXTERNAL PUBLIC USERS ///
    ////////////////////////////

    /**
     * Esta es la unica función de usuario
     * 1. Chequea el dueño del NFT
     * 2. Recoge toda la info del NFT
     * 3. Quema el token y borra token de s_catInfo
     * 4. Retira la info del usuario de s_ownerToCatsTokenId
     * 5. Envia el token a la nueva chain.
     */
    function bridgeNftToAnotherChain(uint64 destChainSelector, address destChainBridge, uint256 tokenId) external {
        // _ownerOf es una funcion de ERC721
        address catOwner = _ownerOf(tokenId);
        require(msg.sender == catOwner);

        CatInfo memory catInfo = s_catInfo[tokenId];
        uint256 idx = catInfo.idx;
        bytes memory data =
            abi.encode(catOwner, catInfo.catName, catInfo.breed, catInfo.image, catInfo.dob, catInfo.shopPartner);

        _burn(tokenId);
        delete s_catInfo[tokenId];

        uint256[] memory userTokenIds = s_ownerToCatsTokenId[msg.sender];
        uint256 lastItem = userTokenIds[userTokenIds.length - 1];

        s_ownerToCatsTokenId[msg.sender].pop();

        if (idx < (userTokenIds.length - 1)) {
            s_ownerToCatsTokenId[msg.sender][idx] = lastItem;
        }

        emit NFTBridgeRequestSent(block.chainid, destChainSelector, destChainBridge, tokenId);
        i_kittyBridge.bridgeNftWithData(destChainSelector, destChainBridge, data);
    }

    /////////////////////////////
    // EXTERNAL PUBLIC SHOP  ///
    ////////////////////////////
    /**
     * @notice Allows the shop partners to mint a cat nft to owner when a purchase is made by user (cat owner)
     * @param catOwner The owner of new cat
     * @param catIpfsHash The image Ipfs Hash for the cat bought by catOwner
     * @param catName Name of cat
     * @param breed Breed of cat
     * @param dob timestamp of date of birth of cat (in seconds)
     * @dev Payments for the cat purchase takes off-chain and a corresponding NFT is minted to the owner which stores the info of cat
     */
    function mintCatToNewOwner(
        address catOwner,
        string memory catIpfsHash,
        string memory catName,
        string memory breed,
        uint256 dob
    ) external onlyShopPartner {
        // 1. Comprueba que la address facilitada no es una tienda.
        require(!s_isKittyShop[catOwner], "KittyConnect__CatOwnerCantBeShopPartner");

        // 2. suma 1 al counter
        uint256 tokenId = kittyTokenCounter;
        kittyTokenCounter++;

        // 3. Carga los datos del cat
        s_catInfo[tokenId] = CatInfo({
            catName: catName,
            breed: breed,
            image: catIpfsHash,
            dob: dob,
            prevOwner: new address[](0),
            shopPartner: msg.sender,
            idx: s_ownerToCatsTokenId[catOwner].length
        });

        // 4. Suma el usuario como cat owner
        s_ownerToCatsTokenId[catOwner].push(tokenId);

        // 5. mintea el NFT
        _safeMint(catOwner, tokenId);
        emit CatMinted(tokenId, catIpfsHash);
    }

    /*
     * @audit-qa los usuarios pueden usar transferFrom para transferir el nft sin pasar por una shop --DONE
     */

    /**
     * @notice it is used to facilitate transfer of cat ownership to new owner
     * @notice but requires the approval of the cat owner to the new owner before shop partner calls this
     */
    function safeTransferFrom(address currCatOwner, address newOwner, uint256 tokenId, bytes memory data)
        public
        override
        onlyShopPartner
    {
        require(_ownerOf(tokenId) == currCatOwner, "KittyConnect__NotKittyOwner");

        require(getApproved(tokenId) == newOwner, "KittyConnect__NewOwnerNotApproved");

        _updateOwnershipInfo(currCatOwner, newOwner, tokenId);

        emit CatTransferredToNewOwner(currCatOwner, newOwner, tokenId);
        _safeTransfer(currCatOwner, newOwner, tokenId, data);
    }

    /////////////////////////////
    // EXTERNAL PUBLIC OWNER ///
    ////////////////////////////

    /*
     * @audit-qa falta una funcion para transferir el ownership. ----DONE
     */

    /**
     * @notice Allows the owner of the protocol to add a new shop partner
     * @param shopAddress The address of new shop partner
     */
    /*
     * @audit-qa no comprueba que el owner de un cat se convierta en tienda a posteriori.
     * ver require de funcion    mintCatToNewOwner -- DONE!!!!
     */
    /*
      * @audit-qa addShop: Can only add shops, not remove; potential clutter or misuse if a shop is compromised.
      */
    function addShop(address shopAddress) external onlyKittyConnectOwner {
        s_isKittyShop[shopAddress] = true;
        s_kittyShops.push(shopAddress);
        emit ShopPartnerAdded(shopAddress);
    }

    /////////////////////////////
    // EXTERNAL PUBLIC BRIDGE ///
    ////////////////////////////

    function mintBridgedNFT(bytes memory data) external onlyKittyBridge {
        (
            address catOwner,
            string memory catName,
            string memory breed,
            string memory imageIpfsHash,
            uint256 dob,
            address shopPartner
        ) = abi.decode(data, (address, string, string, string, uint256, address));

        uint256 tokenId = kittyTokenCounter;
        kittyTokenCounter++;

        s_catInfo[tokenId] = CatInfo({
            catName: catName,
            breed: breed,
            image: imageIpfsHash,
            dob: dob,
            prevOwner: new address[](0),
            shopPartner: shopPartner,
            idx: s_ownerToCatsTokenId[catOwner].length
        });

        emit NFTBridged(block.chainid, tokenId);
        _safeMint(catOwner, tokenId);
    }

    /////////////////////////////
    // INTERNAL               ///
    ////////////////////////////

    function _updateOwnershipInfo(address currCatOwner, address newOwner, uint256 tokenId) internal {
        s_catInfo[tokenId].prevOwner.push(currCatOwner);
        s_catInfo[tokenId].idx = s_ownerToCatsTokenId[newOwner].length;
        s_ownerToCatsTokenId[newOwner].push(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    /////////////////////////////
    // VIEW                    ///
    ////////////////////////////

    /**
     * @notice returns the token uri of the corresponding cat nft
     * @param tokenId The token id of cat
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        CatInfo memory catInfo = s_catInfo[tokenId];

        string memory catTokenUri = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                catInfo.catName,
                '", "breed": "',
                catInfo.breed,
                '", "image": "',
                catInfo.image,
                '", "dob": ',
                Strings.toString(catInfo.dob),
                ', "owner": "',
                Strings.toHexString(_ownerOf(tokenId)),
                '", "shopPartner": "',
                Strings.toHexString(catInfo.shopPartner),
                '"}'
            )
        );
        return string.concat(_baseURI(), catTokenUri);
    }

    /**
     * @notice Returns the age of cat in seconds
     * @param tokenId The token id of cat
     */
    function getCatAge(uint256 tokenId) external view returns (uint256) {
        return block.timestamp - s_catInfo[tokenId].dob;
    }

    function getTokenCounter() external view returns (uint256) {
        return kittyTokenCounter;
    }

    function getKittyConnectOwner() external view returns (address) {
        return i_kittyConnectOwner;
    }

    function getAllKittyShops() external view returns (address[] memory) {
        return s_kittyShops;
    }

    function getKittyShopAtIdx(uint256 idx) external view returns (address) {
        return s_kittyShops[idx];
    }

    function getIsKittyPartnerShop(address partnerShop) external view returns (bool) {
        return s_isKittyShop[partnerShop];
    }

    function getCatInfo(uint256 tokenId) external view returns (CatInfo memory) {
        return s_catInfo[tokenId];
    }

    function getCatsTokenIdOwnedBy(address user) external view returns (uint256[] memory) {
        return s_ownerToCatsTokenId[user];
    }

    function getKittyBridge() external view returns (address) {
        return address(i_kittyBridge);
    }
}
