pass() {
    echo ==========
    echo "Running and expecting success: $@"
    "$@"
    if [ $? -ne 0 ]; then
        echo "Command failed: $@"
        exit 1
    fi
}
fail() {
    echo ==========
    echo "Running and expecting failure: $@"
    "$@"
    if [ $? -eq 0 ]; then
        echo "Command succeeded when it should have failed: $@"
        exit 1
    fi
}
compare_json() {
    echo ==========
    echo "Comparing $1 and $2"
    python3 test_compare_json.py $1 $2
    if [ $? -ne 0 ]; then
        echo "JSON Comparison failed"
        exit 1
    fi
}

## cleanup
python3 -m coverage combine
python3 -m coverage erase
rm -rf test_data/
tar xvf test_data.tar
mkdir test_data/result

## common failures
fail python3 -m coverage run -p ./megawarc
fail python3 -m coverage run -p ./megawarc --verbose --deterministic pack --server https://legacy-api.arpa.li/dictionary test_data/result/zstd_bad_name test_data/pack/zstd_bad_name/bad_name.warc.zst

## pack zst
pass python3 -m coverage run -p ./megawarc --verbose --deterministic pack --server https://legacy-api.arpa.li/dictionary test_data/result/zstd_valid test_data/pack/zstd_valid/
# gzip header includes timestamp, so hashes won't match compressed
pass gzip -d -f test_data/result/zstd_valid.1743749844.megawarc.json.gz
compare_json test_data/result_expected/zstd_valid.1743749844.megawarc.json test_data/result/zstd_valid.1743749844.megawarc.json
# extract rejected files to check their hashes since the .tar header is not reproducible
pass tar xvf test_data/result/zstd_valid.1743749844.megawarc.tar -C test_data/result/
pass sha256sum -c test_data/result_expected/checksums_zstd_valid.txt

## pack gzip
pass python3 -m coverage run -p ./megawarc --verbose --deterministic pack --server https://legacy-api.arpa.li/dictionary test_data/result/gz_valid test_data/pack/gz_valid/
# gzip header includes timestamp, so hashes won't match compressed
pass gzip -d -k -f test_data/result/gz_valid.megawarc.json.gz
compare_json test_data/result_expected/gz_valid.megawarc.json test_data/result/gz_valid.megawarc.json
# extract rejected files to check their hashes since the .tar header is not reproducible
pass tar xvf test_data/result/gz_valid.megawarc.tar -C test_data/result/
pass sha256sum -c test_data/result_expected/checksums_gz_valid.txt

## restore gzip
pass python3 -m coverage run -p ./megawarc --verbose restore test_data/result/gz_valid
pass tar xvf test_data/result/gz_valid -C test_data/result/
pass sha256sum -c test_data/result_expected/checksum_gzip_valid_restore.txt

# convert back
rm test_data/result/gz_valid.megawarc*
pass python3 -m coverage run -p ./megawarc --verbose convert test_data/result/gz_valid
# gzip header includes timestamp, so hashes won't match compressed
pass gzip -d -k -f test_data/result/gz_valid.megawarc.json.gz
compare_json test_data/result_expected/gz_valid_rebuilt.megawarc.json test_data/result/gz_valid.megawarc.json
# extract rejected files to check their hashes
pass tar xvf test_data/result/gz_valid.megawarc.tar -C test_data/result/
pass sha256sum -c test_data/result_expected/checksums_gz_valid.txt

python3 -m coverage combine
python3 -m coverage xml