#ifndef URBACKUP_TIGER_WIRE_H
#define URBACKUP_TIGER_WIRE_H
inline void tiger_store_le32(unsigned int value, char bytes[4]) {
    bytes[0] = static_cast<char>(value);
    bytes[1] = static_cast<char>(value >> 8);
    bytes[2] = static_cast<char>(value >> 16);
    bytes[3] = static_cast<char>(value >> 24);
}
#endif
