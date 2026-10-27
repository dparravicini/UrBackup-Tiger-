#ifndef URBACKUP_TIGER_COMPAT_H
#define URBACKUP_TIGER_COMPAT_H
#include <vector>
#include <string>
template<class T> T* tiger_vector_data(std::vector<T>& v) {
    return v.empty() ? NULL : &v[0];
}
template<class T> const T* tiger_vector_data(const std::vector<T>& v) {
    return v.empty() ? NULL : &v[0];
}
inline const char* tiger_vector_data(const std::string& v) { return v.data(); }
#endif
