/*
 * ngtcp2
 *
 * Copyright (c) 2017 ngtcp2 contributors
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
#include "ngtcp2_conv_test.h"

#include <stdio.h>

#include "ngtcp2_conv.h"
#include "ngtcp2_net.h"
#include "ngtcp2_test_helper.h"

static const MunitTest tests[] = {
    munit_void_test(test_ngtcp2_get_varint),
    munit_void_test(test_ngtcp2_get_uvarintlen),
    munit_void_test(test_ngtcp2_put_uvarintlen),
    munit_void_test(test_ngtcp2_get_uint64),
    munit_void_test(test_ngtcp2_get_uint48),
    munit_void_test(test_ngtcp2_get_uint32),
    munit_void_test(test_ngtcp2_get_uint24),
    munit_void_test(test_ngtcp2_get_uint16),
    munit_void_test(test_ngtcp2_get_uint16be),
    munit_void_test(test_ngtcp2_nth_server_bidi_id),
    munit_void_test(test_ngtcp2_nth_server_uni_id),
    munit_void_test(test_ngtcp2_nth_client_bidi_id),
    munit_void_test(test_ngtcp2_nth_client_uni_id),
    munit_test_end(),
};

const MunitSuite conv_suite = {
    "/conv", tests, NULL, 1, MUNIT_SUITE_OPTION_NONE,
};

void test_ngtcp2_get_varint(void) {
  uint8_t buf[256];
  const uint8_t *p;
  uint64_t n;
  int64_t s;

  /* 0 */
  n = 1;
  p = ngtcp2_put_uvarint(buf, 0);

  assert_ptrdiff(1, ==, p - buf);

  p = ngtcp2_get_uvarint(&n, buf);

  assert_ptrdiff(1, ==, p - buf);
  assert_uint64(0, ==, n);

  /* 63 */
  n = 0;
  p = ngtcp2_put_uvarint(buf, 63);

  assert_ptrdiff(1, ==, p - buf);

  p = ngtcp2_get_uvarint(&n, buf);

  assert_ptrdiff(1, ==, p - buf);
  assert_uint64(63, ==, n);

  /* 64 */
  n = 0;
  p = ngtcp2_put_uvarint(buf, 64);

  assert_ptrdiff(2, ==, p - buf);

  p = ngtcp2_get_uvarint(&n, buf);

  assert_ptrdiff(2, ==, p - buf);
  assert_uint64(64, ==, n);

  /* 16383 */
  n = 0;
  p = ngtcp2_put_uvarint(buf, 16383);

  assert_ptrdiff(2, ==, p - buf);

  p = ngtcp2_get_uvarint(&n, buf);

  assert_ptrdiff(2, ==, p - buf);
  assert_uint64(16383, ==, n);

  /* 16384 */
  n = 0;
  p = ngtcp2_put_uvarint(buf, 16384);

  assert_ptrdiff(4, ==, p - buf);

  p = ngtcp2_get_uvarint(&n, buf);

  assert_ptrdiff(4, ==, p - buf);
  assert_uint64(16384, ==, n);

  /* 1073741823 */
  n = 0;
  p = ngtcp2_put_uvarint(buf, 1073741823);

  assert_ptrdiff(4, ==, p - buf);

  p = ngtcp2_get_uvarint(&n, buf);

  assert_ptrdiff(4, ==, p - buf);
  assert_uint64(1073741823, ==, n);

  /* 1073741824 */
  n = 0;
  p = ngtcp2_put_uvarint(buf, 1073741824);

  assert_ptrdiff(8, ==, p - buf);

  p = ngtcp2_get_uvarint(&n, buf);

  assert_ptrdiff(8, ==, p - buf);
  assert_uint64(1073741824, ==, n);

  /* 4611686018427387903 */
  n = 0;
  p = ngtcp2_put_uvarint(buf, 4611686018427387903ULL);

  assert_ptrdiff(8, ==, p - buf);

  p = ngtcp2_get_uvarint(&n, buf);

  assert_ptrdiff(8, ==, p - buf);
  assert_uint64(4611686018427387903ULL, ==, n);

  /* Check signed version */
  s = 0;
  p = ngtcp2_put_uvarint(buf, 4611686018427387903ULL);

  assert_ptrdiff(8, ==, p - buf);

  p = ngtcp2_get_varint(&s, buf);

  assert_ptrdiff(8, ==, p - buf);
  assert_int64(4611686018427387903LL, ==, s);
}

void test_ngtcp2_get_uvarintlen(void) {
  uint8_t c;

  c = 0x00;

  assert_size(1, ==, ngtcp2_get_uvarintlen(&c));

  c = 0x40;

  assert_size(2, ==, ngtcp2_get_uvarintlen(&c));

  c = 0x80;

  assert_size(4, ==, ngtcp2_get_uvarintlen(&c));

  c = 0xc0;

  assert_size(8, ==, ngtcp2_get_uvarintlen(&c));
}

void test_ngtcp2_get_uint64(void) {
  uint8_t buf[256];
  const uint8_t *p;
  uint64_t n;

  /* 0 */
  n = 1;
  p = ngtcp2_put_uint64be(buf, 0);

  assert_ptrdiff(sizeof(n), ==, p - buf);

  p = ngtcp2_get_uint64(&n, buf);

  assert_ptrdiff(sizeof(n), ==, p - buf);
  assert_uint64(0, ==, n);

  /* 12345678900 */
  n = 0;
  p = ngtcp2_put_uint64be(buf, 12345678900ULL);

  assert_ptrdiff(sizeof(n), ==, p - buf);

  p = ngtcp2_get_uint64(&n, buf);

  assert_ptrdiff(sizeof(n), ==, p - buf);
  assert_uint64(12345678900ULL, ==, n);

  /* 18446744073709551615 */
  n = 0;
  p = ngtcp2_put_uint64be(buf, 18446744073709551615ULL);

  assert_ptrdiff(sizeof(n), ==, p - buf);

  p = ngtcp2_get_uint64(&n, buf);

  assert_ptrdiff(sizeof(n), ==, p - buf);
  assert_uint64(18446744073709551615ULL, ==, n);
}

void test_ngtcp2_get_uint48(void) {
  uint8_t buf[256];
  const uint8_t *p;
  uint64_t n;

  /* 0 */
  n = 1;
  p = ngtcp2_put_uint48be(buf, 0);

  assert_ptrdiff(6, ==, p - buf);

  p = ngtcp2_get_uint48(&n, buf);

  assert_ptrdiff(6, ==, p - buf);
  assert_uint64(0, ==, n);

  /* 123456789 */
  n = 0;
  p = ngtcp2_put_uint48be(buf, 123456789);

  assert_ptrdiff(6, ==, p - buf);

  p = ngtcp2_get_uint48(&n, buf);

  assert_ptrdiff(6, ==, p - buf);
  assert_uint64(123456789, ==, n);

  /* 281474976710655 */
  n = 0;
  p = ngtcp2_put_uint48be(buf, 281474976710655ULL);

  assert_ptrdiff(6, ==, p - buf);

  p = ngtcp2_get_uint48(&n, buf);

  assert_ptrdiff(6, ==, p - buf);
  assert_uint64(281474976710655ULL, ==, n);
}

void test_ngtcp2_get_uint32(void) {
  uint8_t buf[256];
  const uint8_t *p;
  uint32_t n;

  /* 0 */
  n = 1;
  p = ngtcp2_put_uint32be(buf, 0);

  assert_ptrdiff(sizeof(n), ==, p - buf);

  p = ngtcp2_get_uint32(&n, buf);

  assert_ptrdiff(sizeof(n), ==, p - buf);
  assert_uint64(0, ==, n);

  /* 123456 */
  n = 0;
  p = ngtcp2_put_uint32be(buf, 123456);

  assert_ptrdiff(sizeof(n), ==, p - buf);

  p = ngtcp2_get_uint32(&n, buf);

  assert_ptrdiff(sizeof(n), ==, p - buf);
  assert_uint64(123456, ==, n);

  /* 4294967295 */
  n = 0;
  p = ngtcp2_put_uint32be(buf, 4294967295UL);

  assert_ptrdiff(sizeof(n), ==, p - buf);

  p = ngtcp2_get_uint32(&n, buf);

  assert_ptrdiff(sizeof(n), ==, p - buf);
  assert_uint64(4294967295UL, ==, n);
}

void test_ngtcp2_get_uint24(void) {
  uint8_t buf[256];
  const uint8_t *p;
  uint32_t n;

  /* 0 */
  n = 1;
  p = ngtcp2_put_uint24be(buf, 0);

  assert_ptrdiff(3, ==, p - buf);

  p = ngtcp2_get_uint24(&n, buf);

  assert_ptrdiff(3, ==, p - buf);
  assert_uint64(0, ==, n);

  /* 12345 */
  n = 0;
  p = ngtcp2_put_uint24be(buf, 12345);

  assert_ptrdiff(3, ==, p - buf);

  p = ngtcp2_get_uint24(&n, buf);

  assert_ptrdiff(3, ==, p - buf);
  assert_uint64(12345, ==, n);

  /* 16777215 */
  n = 0;
  p = ngtcp2_put_uint24be(buf, 16777215);

  assert_ptrdiff(3, ==, p - buf);

  p = ngtcp2_get_uint24(&n, buf);

  assert_ptrdiff(3, ==, p - buf);
  assert_uint64(16777215, ==, n);
}

void test_ngtcp2_get_uint16(void) {
  uint8_t buf[256];
  const uint8_t *p;
  uint16_t n;

  /* 0 */
  n = 1;
  p = ngtcp2_put_uint16be(buf, 0);

  assert_ptrdiff(sizeof(n), ==, p - buf);

  p = ngtcp2_get_uint16(&n, buf);

  assert_ptrdiff(sizeof(n), ==, p - buf);
  assert_uint64(0, ==, n);

  /* 1234 */
  n = 0;
  p = ngtcp2_put_uint16be(buf, 1234);

  assert_ptrdiff(sizeof(n), ==, p - buf);

  p = ngtcp2_get_uint16(&n, buf);

  assert_ptrdiff(sizeof(n), ==, p - buf);
  assert_uint64(1234, ==, n);

  /* 65535 */
  n = 0;
  p = ngtcp2_put_uint16be(buf, 65535);

  assert_ptrdiff(sizeof(n), ==, p - buf);

  p = ngtcp2_get_uint16(&n, buf);

  assert_ptrdiff(sizeof(n), ==, p - buf);
  assert_uint64(65535, ==, n);
}

void test_ngtcp2_get_uint16be(void) {
  uint8_t buf[256];
  const uint8_t *p;
  uint16_t n;

  /* 0 */
  n = 1;
  p = ngtcp2_put_uint16(buf, 0);

  assert_ptrdiff(sizeof(n), ==, p - buf);

  p = ngtcp2_get_uint16be(&n, buf);

  assert_ptrdiff(sizeof(n), ==, p - buf);
  assert_uint64(0, ==, n);

  /* 1234 */
  n = 0;
  p = ngtcp2_put_uint16(buf, ngtcp2_htons(1234));

  assert_ptrdiff(sizeof(n), ==, p - buf);

  p = ngtcp2_get_uint16be(&n, buf);

  assert_ptrdiff(sizeof(n), ==, p - buf);
  assert_uint16(1234, ==, ngtcp2_ntohs(n));

  /* 65535 */
  n = 0;
  p = ngtcp2_put_uint16(buf, 65535);

  assert_ptrdiff(sizeof(n), ==, p - buf);

  p = ngtcp2_get_uint16be(&n, buf);

  assert_ptrdiff(sizeof(n), ==, p - buf);
  assert_uint64(65535, ==, n);
}

void test_ngtcp2_put_uvarintlen(void) {
  assert_size(1, ==, ngtcp2_put_uvarintlen(0));
  assert_size(1, ==, ngtcp2_put_uvarintlen(63));
  assert_size(2, ==, ngtcp2_put_uvarintlen(64));
  assert_size(2, ==, ngtcp2_put_uvarintlen(16383));
  assert_size(4, ==, ngtcp2_put_uvarintlen(16384));
  assert_size(4, ==, ngtcp2_put_uvarintlen(1073741823));
  assert_size(8, ==, ngtcp2_put_uvarintlen(1073741824));
  assert_size(8, ==, ngtcp2_put_uvarintlen(4611686018427387903ULL));
}

void test_ngtcp2_nth_server_bidi_id(void) {
  assert_int64(0, ==, ngtcp2_nth_server_bidi_id(0));
  assert_int64(1, ==, ngtcp2_nth_server_bidi_id(1));
  assert_int64(5, ==, ngtcp2_nth_server_bidi_id(2));
  assert_int64(9, ==, ngtcp2_nth_server_bidi_id(3));
}

void test_ngtcp2_nth_server_uni_id(void) {
  assert_int64(0, ==, ngtcp2_nth_server_uni_id(0));
  assert_int64(3, ==, ngtcp2_nth_server_uni_id(1));
  assert_int64(7, ==, ngtcp2_nth_server_uni_id(2));
  assert_int64(11, ==, ngtcp2_nth_server_uni_id(3));
}

void test_ngtcp2_nth_client_bidi_id(void) {
  assert_int64(0, ==, ngtcp2_nth_client_bidi_id(0));
  assert_int64(0, ==, ngtcp2_nth_client_bidi_id(1));
  assert_int64(4, ==, ngtcp2_nth_client_bidi_id(2));
  assert_int64(8, ==, ngtcp2_nth_client_bidi_id(3));
}

void test_ngtcp2_nth_client_uni_id(void) {
  assert_int64(0, ==, ngtcp2_nth_client_uni_id(0));
  assert_int64(2, ==, ngtcp2_nth_client_uni_id(1));
  assert_int64(6, ==, ngtcp2_nth_client_uni_id(2));
  assert_int64(10, ==, ngtcp2_nth_client_uni_id(3));
}
