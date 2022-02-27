#include <gtest/gtest.h>
#include "model/cache.h"
#include "model/iobserver.h"
#include "model/agenteobserver.h"
#include <QByteArray>
#include <QDebug>
#include <QSignalSpy>

#define CACHE_ROW_KEY "row"

using namespace testing;

class CacheTest : public ::testing::Test
{
public:
    static Cache<QByteArray> *cache;
    static QApplication *app;

    static void SetUpTestSuite() {
        cache = new Cache<QByteArray>;

        QByteArray array;
        array.push_back(0x21);
        array.push_back(0x11);
        array.push_back(0x43);
        array.push_back(0x43);

        cache->set(CACHE_ROW_KEY, array);
    }

    static void TearDownTestSuite(){
        delete cache;
    }

};

Cache<QByteArray> *CacheTest::cache;

TEST_F(CacheTest, CacheGetAndSet) {

    int sizeSave = cache->rowCount();

    QByteArray array;
    array.push_back(0x01);
    array.push_back(0x23);
    array.push_back(0x43);

    cache->set("test", array);

    ASSERT_LT(sizeSave, cache->rowCount());

    const QByteArray &array2 = cache->get("test");

    ASSERT_EQ(array2.size(), array.size());
    ASSERT_EQ(array.compare(array2), 0);

}

TEST_F(CacheTest, CacheSearch) {

    EXPECT_TRUE(cache->contains(CACHE_ROW_KEY));
    EXPECT_FALSE(cache->contains(""));
    EXPECT_FALSE(cache->contains("testing123"));
}

TEST_F(CacheTest, CacheObserverRowAdded) {

    QByteArray array;
    array.push_back(0x11);
    array.push_back(0x23);
    array.push_back(0x13);
    array.push_back(0x2A);

    AgenteObserver *observer1 = new AgenteObserver("test2");
    AgenteObserver *observer2 = new AgenteObserver("test2");
    AgenteObserver *observer3 = new AgenteObserver("test3");
    cache->attach(observer1);
    cache->attach(observer2);
    cache->attach(observer3);

    QSignalSpy spyAddedObserver1(observer1, SIGNAL(cacheRowAddeded(QString)));
    QSignalSpy spyAddedObserver2(observer2, SIGNAL(cacheRowAddeded(QString)));
    QSignalSpy spyAddedObserver3(observer3, SIGNAL(cacheRowAddeded(QString)));

    cache->set("test2", array);

    ASSERT_EQ(spyAddedObserver1.count(), 1);
    ASSERT_EQ(spyAddedObserver2.count(), 1);
    ASSERT_EQ(spyAddedObserver3.count(), 0);
}

TEST_F(CacheTest, CacheObserverRowUpdated) {

    QByteArray array;
    array.push_back(0x11);
    array.push_back(0x23);
    array.push_back(0x13);
    array.push_back(0x2A);

    QByteArray array2;
    array2.push_back(0x12);
    array2.push_back(0x21);

    AgenteObserver *observer1 = new AgenteObserver("test22");
    AgenteObserver *observer2 = new AgenteObserver("test33");
    cache->attach(observer1);
    cache->attach(observer2);

    QSignalSpy spyObserver1(observer1, SIGNAL(cacheRowUpdated(const QByteArray &)));
    QSignalSpy spyObserver2(observer2, SIGNAL(cacheRowUpdated(const QByteArray &)));

    cache->set("test22", array);
    cache->set("test22", array2);

    const Cache<QByteArray> &cacheConst = *cache;
    const QByteArray &row = cache->get("test22");
    const QByteArray row2 = cacheConst.get("test22");

    ASSERT_TRUE(row == row2 && row == array2);
    ASSERT_FALSE(row == array);

    ASSERT_EQ(spyObserver1.count(), 1);
    ASSERT_EQ(spyObserver2.count(), 0);

}

TEST_F(CacheTest, CacheObserverRowRemoved) {

    QByteArray array;
    array.push_back(0x11);
    array.push_back(0x23);
    array.push_back(0x13);
    array.push_back(0x2A);

    QByteArray array2;
    array2.push_back(0x12);
    array2.push_back(0x21);

    AgenteObserver *observer1 = new AgenteObserver("test222");
    AgenteObserver *observer2 = new AgenteObserver("test333");
    cache->attach(observer1);
    cache->attach(observer2);

    QSignalSpy spyObserver1(observer1, SIGNAL(cacheRowRemoved(QString)));
    QSignalSpy spyObserver2(observer2, SIGNAL(cacheRowRemoved(QString)));

    cache->set("test222", array);
    cache->set("test333", cache->get("test222"));
    cache->remove("test222");

    ASSERT_EQ(spyObserver1.count(), 1);
    ASSERT_EQ(spyObserver2.count(), 0);

}
