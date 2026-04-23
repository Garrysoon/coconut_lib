#!/bin/bash

# 스크립트 실행 중 오류 발생 시 종료
set -e

# 실행 모드: unit | scenario | all
# 기본값: all
MODE="${1:-all}"
case "$MODE" in
  unit)
    TEST_CMD="dart test -t unit --coverage=coverage"
    MODE_LABEL="unit"
    ;;
  scenario)
    TEST_CMD="dart test -t scenario --coverage=coverage"
    MODE_LABEL="scenario"
    ;;
  all)
    TEST_CMD="dart test --coverage=coverage"
    MODE_LABEL="all"
    ;;
  *)
    echo "Usage: $0 [unit|scenario|all]"
    exit 1
    ;;
esac

# 컬러 정의
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
RESET="\033[0m"

# 로딩 텍스트 출력 함수
show_loading() {
    local pid=$1
    local label=$2
    local start_time=$3

    local spin='-\|/'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        local current_time=$(date +%s)
        local elapsed_time=$((current_time - start_time))
        i=$(( (i+1) % 4 ))
        printf "\r${YELLOW}[$label] ${spin:$i:1} ${elapsed_time}s...${RESET}    "
        sleep 0.1
    done
}

# 단계별 시간 측정 함수
measure_step() {
    local step_name=$1
    local step_command=$2

    local start_time=$(date +%s)
    eval "$step_command" &
    local pid=$!
    show_loading $pid "$step_name" "$start_time"
    wait $pid
    local end_time=$(date +%s)

    local duration=$((end_time - start_time))
    printf "\r${GREEN}[$step_name] Done! (${duration}s)${RESET}         \n"
}

# 전체 시작 시간
total_start_time=$(date +%s)

# 1. 테스트 실행 및 커버리지 데이터 수집
echo "${BLUE}Step 1/3: Running ${MODE_LABEL} tests and collecting coverage data...${RESET}"
measure_step "Step 1. Running tests" "${TEST_CMD} >/dev/null 2>&1"

# 2. 포맷팅 및 lcov 파일 생성
echo "${BLUE}Step 2/3: Formatting coverage data into lcov format...${RESET}"
measure_step "Step 2. Formatting coverage data" "dart pub global run coverage:format_coverage \
    --packages=.dart_tool/package_config.json \
    --lcov \
    -i coverage/test \
    -o coverage/lcov.info \
    --report-on=lib >/dev/null 2>&1"

# 3. lcov 파일을 HTML로 변환하며 .g.dart 파일 제외
echo "${BLUE}Step 3/3: Generating HTML report from lcov...${RESET}"
measure_step "Step 3. Generating HTML report" "genhtml -o coverage/html coverage/lcov.info >/dev/null 2>&1"

# 전체 종료 시간
total_end_time=$(date +%s)
total_duration=$((total_end_time - total_start_time))

# 결과 출력
echo "${GREEN}Coverage report successfully generated!${RESET}"
echo "${GREEN}Location: coverage/html/index.html${RESET}"
echo "${BLUE}Total execution time: ${total_duration}s${RESET}"

open coverage/html/index.html