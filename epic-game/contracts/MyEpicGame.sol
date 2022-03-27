// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


import "hardhat/console.sol";

import './libraries/Base64.sol';

contract MyEpicGame is ERC721{

    struct CharacterAttributes {
        uint characterIndex;
        string name;
        string imageURI;
        uint hp;
        uint maxHp;
        uint attackDamage;
    }
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    CharacterAttributes [] defaultCharacters;

    mapping(uint256 => CharacterAttributes) public nftHolderAttributes;
    mapping(address => uint256) public nftHolders;

    struct BigBoss {
        string name;
        string imageURI;
        uint hp;
        uint maxHp;
        uint attackDamage;
        }
    BigBoss public bigBoss;


    constructor(
        string [] memory characterNames,
        string [] memory characterImageURIs,
        uint [] memory characterHp,
        uint [] memory characterAttackDmg,
        string memory bossName,
        string memory bossImageURI,
        uint bossHp,
        uint bossAttackDamage
    )
    ERC721("Hackers", "HACK") 
    {
        bigBoss = BigBoss({
        name: bossName,
        imageURI: bossImageURI,
        hp: bossHp,
        maxHp: bossHp,
        attackDamage: bossAttackDamage
        });
        console.log("Done initializing boss %s w/ HP %s, img %s", bigBoss.name, bigBoss.hp, bigBoss.imageURI);
        
        for(uint i = 0; i < characterNames.length; i += 1) {
            defaultCharacters.push(CharacterAttributes({
            characterIndex: i,
            name: characterNames[i],
            imageURI: characterImageURIs[i],
            hp: characterHp[i],
            maxHp: characterHp[i],
            attackDamage: characterAttackDmg[i]
        }));

        CharacterAttributes memory c = defaultCharacters[i];
        console.log("Done initializing %s w/ HP %s, img %s", c.name, c.hp, c.imageURI);
        }
    _tokenIds.increment();   
    }

    function mintCharacterNFT(uint _characterIndex) external {
        uint newItemId = _tokenIds.current();

        _safeMint(msg.sender, newItemId);

        nftHolderAttributes[newItemId] = CharacterAttributes({
            characterIndex: _characterIndex,
            name: defaultCharacters[_characterIndex].name,
            imageURI: defaultCharacters[_characterIndex].imageURI,
            hp: defaultCharacters[_characterIndex].hp,
            maxHp: defaultCharacters[_characterIndex].maxHp,
            attackDamage: defaultCharacters[_characterIndex].attackDamage
        });
        console.log("Minted NFT w/ tokenId %s and characterIndex %s", newItemId, _characterIndex);
        nftHolders[msg.sender] = newItemId;
        _tokenIds.increment();
        emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        CharacterAttributes memory charAttributes = nftHolderAttributes[_tokenId];

        string memory strHp = Strings.toString(charAttributes.hp);
        string memory strMaxHp = Strings.toString(charAttributes.maxHp);
        string memory strAttackDamage = Strings.toString(charAttributes.attackDamage);

        string memory json = Base64.encode(
            abi.encodePacked(
            '{"name": "',
            charAttributes.name,
            ' -- NFT #: ',
            Strings.toString(_tokenId),
            '", "description": "An NFT data game", "image": "ipfs://',
            charAttributes.imageURI,
            '", "attributes": [ { "trait_type": "Health Points", "value": ',strHp,', "max_value":',strMaxHp,'}, { "trait_type": "Attack Damage", "value": ',
            strAttackDamage,'} ]}'
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
  
        return output;
    }

    function attackBoss() public {

        uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
        CharacterAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];
        

        console.log("\nPlayer w/ character %s about to attack. Has %s HP and %s AD", player.name, player.hp, player.attackDamage);
        console.log("Boss %s has %s HP and %s AD", bigBoss.name, bigBoss.hp, bigBoss.attackDamage);
        
        require (player.hp > 0, "Error: character must have HP to attack boss.");

        require (bigBoss.hp > 0,"Error: boss must have HP to attack boss.");
        // Pseudo random attack hit chance
        uint256 seed = (block.difficulty + block.timestamp) % 100;
        console.log('seed: ',seed);
        uint256 playerAttackDamage = player.attackDamage;
        uint256 bigBossAttackDamage = bigBoss.attackDamage;
        if(seed <= 5){
            playerAttackDamage = playerAttackDamage * 2;
        }
        if(seed >= 80){
            bigBossAttackDamage = 0;
        }        
        if (bigBoss.hp < playerAttackDamage) {
            bigBoss.hp = 0;
        } else {
            bigBoss.hp = bigBoss.hp - playerAttackDamage;
        }

        if (player.hp < bigBossAttackDamage) {
            player.hp = 0;
        } else {
            player.hp = player.hp - bigBossAttackDamage;
        }

        console.log("Player attacked boss. New boss hp: %s", bigBoss.hp);
        console.log("Boss attacked player. New player hp: %s\n", player.hp);
        emit AttackComplete(bigBoss.hp, player.hp);
        }

        function checkIfUserHasNFT() public view returns (CharacterAttributes memory) {
            uint256 userNftTokenId = nftHolders[msg.sender];

            if (userNftTokenId > 0) {
                return nftHolderAttributes[userNftTokenId];
            }
            else {
                CharacterAttributes memory emptyStruct;
                return emptyStruct;
            }
        }
        
        function getAllDefaultCharacters() public view returns (CharacterAttributes[] memory) {
            return defaultCharacters;
        }

        function getBigBoss() public view returns (BigBoss memory) {
            return bigBoss;
        }

        function getAllPlayers() public view returns (CharacterAttributes [] memory) {
            CharacterAttributes [] memory allPlayers = new CharacterAttributes [](_tokenIds.current()-1);
            
            for(uint i =1; i < _tokenIds.current(); i++){
                CharacterAttributes storage player = nftHolderAttributes[i];
                allPlayers[i-1] = player;
            }
            return allPlayers;
        }

        event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
        event AttackComplete(uint newBossHp, uint newPlayerHp);
}
