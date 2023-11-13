""" 
This is a simple script to help quickly convert t_infomask and t_infomask2 values to their 
human-readable interpretations.
contributor: mssysm@

References:
infomask source - https://github.com/postgres/postgres/blob/master/src/include/access/htup_details.h#L187-L273
infomask2 source - https://github.com/postgres/postgres/blob/master/src/include/access/htup_details.h#L274-L285

Example usage:
Say you have the infomask and infomask2 values for a ctid and you want to know what they mean.
t_ctid	    t_infomask2	    t_infomask
(126372,4)	8221	        1283
(126243,78)	49181	        9507

You can run this script and enter the values to get the following output:
$ python convert_infomasks.py
Enter t_infomask value: 1283
Enter t_infomask2 value: 8221
Interpretation for t_infomask:
- HEAP_HASNULL
- HEAP_HASVARWIDTH
- HEAP_XMIN_COMMITTED
- HEAP_XMAX_COMMITTED

Interpretation for t_infomask2:
- HEAP_NATTS_MASK
- HEAP_KEYS_UPDATED
- 29 attributes

$ python convert_infomasks.py
Enter t_infomask value: 9507
Enter t_infomask2 value: 49181
Interpretation for t_infomask:
- HEAP_HASNULL
- HEAP_HASVARWIDTH
- HEAP_COMBOCID
- HEAP_XMIN_COMMITTED
- HEAP_XMAX_COMMITTED
- HEAP_UPDATED

Interpretation for t_infomask2:
- HEAP_NATTS_MASK
- HEAP_HOT_UPDATED
- HEAP_ONLY_TUPLE
- 29 attributes


"""
def decode_infomask(infomask):
    MASKS = {
        0x0001: "HEAP_HASNULL",
        0x0002: "HEAP_HASVARWIDTH",
        0x0004: "HEAP_HASEXTERNAL",
        0x0010: "HEAP_XMAX_KEYSHR_LOCK",
        0x0020: "HEAP_COMBOCID",
        0x0040: "HEAP_XMAX_EXCL_LOCK",
        0x0080: "HEAP_XMAX_LOCK_ONLY",
        0x0100: "HEAP_XMIN_COMMITTED",
        0x0200: "HEAP_XMIN_INVALID",
        0x0400: "HEAP_XMAX_COMMITTED",
        0x0800: "HEAP_XMAX_INVALID",
        0x1000: "HEAP_XMAX_IS_MULTI",
        0x2000: "HEAP_UPDATED",
        0x4000: "HEAP_MOVED_OFF",
        0x8000: "HEAP_MOVED_IN"
    }

    result = []
    for mask, desc in MASKS.items():
        if infomask & mask:
            result.append(desc)

    return result

def decode_infomask2(infomask2):
    MASKS2 = {
        0x07FF: "HEAP_NATTS_MASK",  # This is a special case; will handle separately
        0x2000: "HEAP_KEYS_UPDATED",
        0x4000: "HEAP_HOT_UPDATED",
        0x8000: "HEAP_ONLY_TUPLE"
    }

    result = []
    for mask, desc in MASKS2.items():
        if infomask2 & mask:
            result.append(desc)

    # Special handling for HEAP_NATTS_MASK
    num_attributes = infomask2 & 0x07FF
    result.append(f"{num_attributes} attributes")

    return result

if __name__ == "__main__":
    infomask = int(input("Enter t_infomask value: "))
    infomask2 = int(input("Enter t_infomask2 value: "))

    print("Interpretation for t_infomask:")
    for item in decode_infomask(infomask):
        print(f"- {item}")

    print("\nInterpretation for t_infomask2:")
    for item in decode_infomask2(infomask2):
        print(f"- {item}")
