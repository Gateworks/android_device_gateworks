/*
 * Copyright 2014 Intel Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <limits.h>
#include "edify/expr.h"

/* file_write(path, value) */
static Value *
FileWriteFn(const char *name, State *state, int argc, Expr * argv[])
{
    char *result = NULL, *path, *value;
    char file_path[PATH_MAX];
    int ret, t;
    FILE *f;

    if (ReadArgs(state, argv, 2, &path, &value) < 0) {
	fprintf(stderr, "%s: usage: file_write(path, value).", __func__);
	return NULL;
    }

    strncpy(file_path, path, PATH_MAX);

    fprintf(stderr, "%s: writing %s to %s\n", __func__, value, file_path);
    f = fopen(file_path, "wb");
    if (!f) {
	fprintf(stderr, "%s: can't open file:%s\n", __func__, file_path);
	return StringValue(strdup(""));
    }

    ret = fwrite(value, strlen(value), 1, f);

    if (ret < 0) {
	fprintf(stderr, "%s: error on writing file:%s :%s\n",
		__func__, file_path, strerror(errno));
	fclose(f);
	return StringValue(strdup(""));
    }

    fclose(f);
    return StringValue(strdup("t"));
}

void Register_librecovery_updater_ventana() {
	RegisterFunction("file_write", FileWriteFn);
}
