package srt

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestStreamIDUnmarshal(t *testing.T) {
	for _, ca := range []struct {
		name string
		raw  string
		dec  streamID
	}{
		{
			"mediamtx syntax 1",
			"read:mypath",
			streamID{
				mode: streamIDModeRead,
				path: "mypath",
			},
		},
		{
			"mediamtx syntax 2",
			"publish:mypath:myquery",
			streamID{
				mode:  streamIDModePublish,
				path:  "mypath",
				query: "myquery",
			},
		},
		{
			"mediamtx syntax path query",
			"publish:mypath?param=value",
			streamID{
				mode:  streamIDModePublish,
				path:  "mypath",
				query: "param=value",
			},
		},
		{
			"mediamtx syntax path encoded query",
			"publish:mypath?param1=value1%26param2=value2",
			streamID{
				mode:  streamIDModePublish,
				path:  "mypath",
				query: "param1=value1&param2=value2",
			},
		},
		{
			"mediamtx syntax 3",
			"read:mypath:myuser:mypass:myquery",
			streamID{
				mode:  streamIDModeRead,
				path:  "mypath",
				user:  "myuser",
				pass:  "mypass",
				query: "myquery",
			},
		},
		{
			"standard syntax",
			"#!::u=johnny,t=file,m=publish,r=results.csv,s=mypass,h=myhost.com",
			streamID{
				mode: streamIDModePublish,
				path: "results.csv",
				user: "johnny",
				pass: "mypass",
			},
		},
		{
			"standard syntax path query",
			"#!::m=publish,r=results.csv?param=value",
			streamID{
				mode:  streamIDModePublish,
				path:  "results.csv",
				query: "param=value",
			},
		},
		{
			"standard syntax path encoded query",
			"#!::m=publish,r=results.csv?param1=value1%26param2=value2",
			streamID{
				mode:  streamIDModePublish,
				path:  "results.csv",
				query: "param1=value1&param2=value2",
			},
		},
		{
			"issue 3701",
			"#!::bmd_uuid=0e1df79f-77e6-465c-b099-29a616e964f7,bmd_name=rdt-wp-003,r=test3,m=publish",
			streamID{
				mode: streamIDModePublish,
				path: "test3",
			},
		},
	} {
		t.Run(ca.name, func(t *testing.T) {
			var sid streamID
			err := sid.unmarshal(ca.raw)
			require.NoError(t, err)
			require.Equal(t, ca.dec, sid)
		})
	}
}
