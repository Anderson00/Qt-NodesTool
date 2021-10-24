#include "cache.h"

template<typename T>
Cache<T>::Cache()
{

}

template<typename T>
int Cache<T>::size()
{
    return this->m_general_data.count();
}
