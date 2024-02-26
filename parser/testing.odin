package parser


// test_parser :: proc() {
//     log_info("Testing the Parser")

//     PARSER_PASS_PATH :: "tests/parser/pass"
//     PARSER_FAIL_PATH :: "tests/parser/fail"

//     fd,    _  := os.open(PARSER_PASS_PATH)
//     files, _  := os.read_dir(fd, MAX_FILE_NUMBER)

//     for file in files {
//         file_path := fmt.aprintf("%s/%s", PARSER_PASS_PATH, file.name)
//         data, ok  := os.read_entire_file_from_filename(file_path)

//         expr, expr_parsed := parse_src(data)
//         // fmt.println(expr, expr_parsed)

//         if expr_parsed {
//             log_info(fmt.aprintf("Successfully parsed file %s, as it should", file_path))
//             fmt.println(expression_to_string(expr))
//         } else {
//             log_error(fmt.aprintf("Failed to parse file %s, something is wrong", file.name))
//         }
//     }

//     // fd,    _ = os.open(LEXER_FAIL_PATH)
//     // files, _ = os.read_dir(fd, MAX_FILE_NUMBER)

//     // for file in files {
//     //     file_path := fmt.aprintf("%s/%s", LEXER_FAIL_PATH, file.name)
//     //     data, ok  := os.read_entire_file_from_filename(file_path)

//     //     lexer := lexer_make(data)
//     //     defer lexer_delete(lexer)
//     //     lexer_tokenize(lexer)

//     //     if !lexer_tokenized_successfully(lexer) {
//     //         log_info(fmt.aprintf("Failed to lex file %s, as it should", file.name))
//     //     } else {
//     //         log_error(fmt.aprintf("Successfully lexed file %s, something is wrong", file.name))
//     //     }
//     // }
// }