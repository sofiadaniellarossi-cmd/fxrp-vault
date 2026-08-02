// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Importaciones oficiales verificadas en dev.flare.network para Coston2 testnet.
// Instalar con: npm install @flarenetwork/flare-periphery-contracts
import {ContractRegistry} from "@flarenetwork/flare-periphery-contracts/coston2/ContractRegistry.sol";
import {TestFtsoV2Interface} from "@flarenetwork/flare-periphery-contracts/coston2/TestFtsoV2Interface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title FXRPVault
/// @notice Vault de FXRP: depositar, ver valor en USD en vivo via FTSOv2,
///         y enviar fondos por "link" reclamable (modelo pull).
contract FXRPVault {
    IERC20 public immutable fxrp;
    TestFtsoV2Interface internal ftsoV2;

    // Dirección real de FXRP (FTestXRP) en Coston2, confirmada en el explorer:
    // https://coston2-explorer.flare.network/token/0x0b6A3645c240605887a5532109323A3E12273dc7
    address public constant FXRP_COSTON2 = 0x0b6A3645c240605887a5532109323A3E12273dc7;

    // FXRP tiene 6 decimales (confirmado en el explorer de Coston2).
    uint256 public constant FXRP_DECIMALS = 6;

    struct SendLink {
        address sender;
        uint256 amount;
        bool claimed;
    }

    mapping(address => uint256) public balances;
    mapping(bytes32 => SendLink) public sendLinks;
    uint256 private nonce;

    event Deposited(address indexed user, uint256 amount);
    event LinkCreated(bytes32 indexed linkId, address indexed sender, uint256 amount);
    event LinkClaimed(bytes32 indexed linkId, address indexed claimer, uint256 amount);

    /// @param _fxrpToken Dirección del token FXRP en Coston2. Pasar FXRP_COSTON2.
    constructor(address _fxrpToken) {
        fxrp = IERC20(_fxrpToken);
        // TestFtsoV2Interface: todos los métodos son "view" (gratis, sin gas de escritura).
        // Ideal para demo de hackathon. En producción real se usa FtsoV2Interface,
        // que tiene métodos payable con fee.
        ftsoV2 = ContractRegistry.getTestFtsoV2();
    }

    /// @dev Convierte un nombre de feed (ej. "XRP") a su bytes21 ID.
    /// Patrón oficial: categoría 1 (crypto) + nombre + "/USD".
    function convertToFeedId(string memory _name) internal pure returns (bytes21) {
        return bytes21(
            bytes.concat(
                bytes1(uint8(1)),
                bytes(string.concat(_name, "/USD"))
            )
        );
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        fxrp.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    /// @notice Valor en USD del saldo del usuario, usando el precio XRP/USD en vivo.
    function getUsdValue(address user)
        external
        view
        returns (uint256 usdValue, int8 priceDecimals, uint64 timestamp)
    {
        bytes21 xrpUsdId = convertToFeedId("XRP");
        (uint256 price, int8 dec, uint64 ts) = ftsoV2.getFeedById(xrpUsdId);
        uint256 bal = balances[user];
        usdValue = (bal * price) / (10 ** FXRP_DECIMALS);
        priceDecimals = dec;
        timestamp = ts;
    }

    /// @notice Bloquea `amount` del saldo del emisor y genera un ID de link reclamable.
    function createSendLink(uint256 amount) external returns (bytes32 linkId) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        linkId = keccak256(abi.encodePacked(msg.sender, amount, nonce, block.timestamp));
        nonce++;
        sendLinks[linkId] = SendLink(msg.sender, amount, false);
        emit LinkCreated(linkId, msg.sender, amount);
    }

    /// @notice El receptor llama esto (conectando su wallet) para reclamar el FXRP.
    function claim(bytes32 linkId) external {
        SendLink storage link = sendLinks[linkId];
        require(!link.claimed, "Already claimed");
        require(link.amount > 0, "Invalid link");
        link.claimed = true;
        fxrp.transfer(msg.sender, link.amount);
        emit LinkClaimed(linkId, msg.sender, link.amount);
    }
}
