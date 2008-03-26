/*
 * Copyright (c) 2007-2008, Brian Koropoff
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the Moonunit project nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY BRIAN KOROPOFF ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL BRIAN KOROPOFF BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <moonunit/loader.h>

MuLibrary*
Mu_Loader_Open(struct MuLoader* loader, const char* path, MuError** err)
{
    return loader->open(loader, path, err);
}

struct MuTest**
Mu_Loader_Tests(struct MuLoader* loader, MuLibrary* handle)
{
    return loader->tests(loader, handle);
}

MuThunk
Mu_Loader_LibrarySetup(struct MuLoader* loader, MuLibrary* handle)
{
    return loader->library_setup(loader, handle);
}

MuThunk
Mu_Loader_LibraryTeardown(struct MuLoader* loader, MuLibrary* handle)
{
    return loader->library_teardown(loader, handle);
}

MuTestThunk
Mu_Loader_FixtureSetup(struct MuLoader* loader, MuLibrary* handle, const char* name)
{
    return loader->fixture_setup(loader, name, handle);
}

MuTestThunk
Mu_Loader_FixtureTeardown(struct MuLoader* loader, MuLibrary* handle, const char* name)
{
    return loader->fixture_teardown(loader, name, handle);
}

void
Mu_Loader_Close(struct MuLoader* loader, MuLibrary* handle)
{
    loader->close(loader, handle);
}

const char*
Mu_Loader_Name(struct MuLoader* loader, MuLibrary* handle)
{
    return loader->name(loader, handle);
}
