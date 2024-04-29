/*
 * nghttp3
 *
 * Copyright (c) 2019 nghttp3 contributors
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
#ifndef NGHTTP3_CONN_TEST_H
#define NGHTTP3_CONN_TEST_H

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif /* HAVE_CONFIG_H */

#define MUNIT_ENABLE_ASSERT_ALIASES

#include "munit.h"

extern const MunitSuite conn_suite;

munit_void_test_decl(test_nghttp3_conn_read_control);
munit_void_test_decl(test_nghttp3_conn_write_control);
munit_void_test_decl(test_nghttp3_conn_submit_request);
munit_void_test_decl(test_nghttp3_conn_http_request);
munit_void_test_decl(test_nghttp3_conn_http_resp_header);
munit_void_test_decl(test_nghttp3_conn_http_req_header);
munit_void_test_decl(test_nghttp3_conn_http_content_length);
munit_void_test_decl(test_nghttp3_conn_http_content_length_mismatch);
munit_void_test_decl(test_nghttp3_conn_http_non_final_response);
munit_void_test_decl(test_nghttp3_conn_http_trailers);
munit_void_test_decl(test_nghttp3_conn_http_ignore_content_length);
munit_void_test_decl(test_nghttp3_conn_http_record_request_method);
munit_void_test_decl(test_nghttp3_conn_http_error);
munit_void_test_decl(test_nghttp3_conn_qpack_blocked_stream);
munit_void_test_decl(test_nghttp3_conn_just_fin);
munit_void_test_decl(test_nghttp3_conn_submit_response_read_blocked);
munit_void_test_decl(test_nghttp3_conn_recv_uni);
munit_void_test_decl(test_nghttp3_conn_recv_goaway);
munit_void_test_decl(test_nghttp3_conn_shutdown_server);
munit_void_test_decl(test_nghttp3_conn_shutdown_client);
munit_void_test_decl(test_nghttp3_conn_priority_update);
munit_void_test_decl(test_nghttp3_conn_request_priority);
munit_void_test_decl(test_nghttp3_conn_set_stream_priority);
munit_void_test_decl(test_nghttp3_conn_shutdown_stream_read);
munit_void_test_decl(test_nghttp3_conn_stream_data_overflow);
munit_void_test_decl(test_nghttp3_conn_get_frame_payload_left);
munit_void_test_decl(test_nghttp3_conn_update_ack_offset);

#endif /* NGHTTP3_CONN_TEST_H */
