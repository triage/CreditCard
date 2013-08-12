/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 * This file is part of CreditCard -- an iOS project that provides a smooth and elegant
 * means to enter or edit credit cards. It was inspired by  a similar form created from
 * scratch by Square (https://squareup.com/). To see this form in action visit:
 *
 *   http://functionsource.com/post/beautiful-forms)
 *
 * Copyright 2012 Lot18 Holdings, Inc. All Rights Reserved.
 *
 *
 * Redistribution and use in source and binary forms, with or without modification, are
 * permitted provided that the following conditions are met:
 *
 *    1. Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *
 *    2. Redistributions in binary form must reproduce the above copyright notice, this list
 *       of conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY Lot18 Holdings ''AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL David Hoerl OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import "CreditCard.h"

// See: http://www.regular-expressions.info/creditcard.html
#define VISA_VALID				@"^4[0-9]{15}?"						// VISA 16
#define MASTERCARD_VALID		@"^5[1-5][0-9]{14}$"				// MC 16
#define AMEX_VALID              @"^3[47][0-9]{13}$"					// AMEX 15
#define DISCOVER_VALID			@"^6(?:011|5[0-9]{2})[0-9]{12}$"	// Discover 16
#define DINERS_CLUB_VALID		@"^3(?:0[0-5]|[68][0-9])[0-9]{11}$"	// DinersClub 14 // 38812345678901

#define AMEX_TYPE		@"^3[47][0-9]{2}$"					// AMEX 15
#define DINERS_CLUB_TYPE	@"^3(?:0[0-5]|[68][0-9])[0-9]$"		// DinersClub 14 // 38812345678901
#define VISA_TYPE			@"^4[0-9]{3}?"						// VISA 16
#define MC_TYPE				@"^5[1-5][0-9]{2}$"					// MC 16
#define DISCOVER_TYPE		@"^6(?:011|5[0-9]{2})$"				// Discover 16

#define		kID					@"id"
#define		kCCid				@"id"				// key for record (NSNumber)
#define		kCCnumber			@"card_number"		// key for obfuscated number (string)
#define		kCCtype				@"card_type"		// one of four strings: Master Card, Visa, American Express, Diners Club, and Discover
#define		kCCexpir			@"card_expiration"	// key for expDate in YYYY-MM format (string)
#define		kCCccv				@"card_cvv"			// key for CCV (NSNumber)
#define		kCCaddrID			@"address_id"		// key for Address ID (NSNumber)
#define		kCCdefault			@"default"			// key for is this the default address (NSNumber bool)


//NSRegularExpressions for testing validity
static NSRegularExpression *visaValidityRegex;
static NSRegularExpression *mastercardValidityRegex;
static NSRegularExpression *amexValidityRegex;
static NSRegularExpression *discoverValidityRegex;
static NSRegularExpression *dinersClubValidityRegex;

//NSRegularExpressions for testing CreditCardType with an incomplete number, so that it can be properly formatted as the user types
static NSRegularExpression *visaCardTypeRegex;
static NSRegularExpression *mastercardCardTypeRegex;
static NSRegularExpression *amexCardTypeRegex;
static NSRegularExpression *discoverCardTypeRegex;
static NSRegularExpression *dinersClubCardTypeRegex;

@implementation CreditCard
{
	NSMutableDictionary *privateDict;
}
@synthesize dictionary;

+ (void)initialize
{
	if(self == [CreditCard class]) {
		__autoreleasing NSError *error;
        
        //expressions for determining validity
		visaValidityRegex = [NSRegularExpression regularExpressionWithPattern:VISA_VALID options:0 error:&error];
		mastercardValidityRegex	= [NSRegularExpression regularExpressionWithPattern:MASTERCARD_VALID options:0 error:&error];
		amexValidityRegex = [NSRegularExpression regularExpressionWithPattern:AMEX_VALID options:0 error:&error];
		discoverValidityRegex = [NSRegularExpression regularExpressionWithPattern:DISCOVER_VALID options:0 error:&error];
		dinersClubValidityRegex = [NSRegularExpression regularExpressionWithPattern:DINERS_CLUB_VALID options:0 error:&error];
		
        //expressions for determining CreditCardType from a proposed/incomplete number
		visaCardTypeRegex = [NSRegularExpression regularExpressionWithPattern:VISA_TYPE options:0 error:&error];
		mastercardCardTypeRegex = [NSRegularExpression regularExpressionWithPattern:MC_TYPE options:0 error:&error];
		amexCardTypeRegex = [NSRegularExpression regularExpressionWithPattern:AMEX_TYPE options:0 error:&error];
		discoverCardTypeRegex = [NSRegularExpression regularExpressionWithPattern:DISCOVER_TYPE options:0 error:&error];
		dinersClubCardTypeRegex	= [NSRegularExpression regularExpressionWithPattern:DINERS_CLUB_TYPE options:0 error:&error];
	}
}

+ (NSString *)cleanNumber:(NSString *)str
{
	return [str stringByReplacingOccurrencesOfString:@" " withString:@""];
}

// http://www.regular-expressions.info/creditcard.html
+ (CreditCardType)ccTypeWithCardNumber:(NSString *)proposedNumber
{
	NSRegularExpression *reg;
    
	if([proposedNumber length] < CC_MIN_LENGTH_TO_DETERMINE_CCTYPE) return CreditCardTypeInvalid;
    
	for(NSUInteger idx = 0; idx < CreditCardTypeInvalid; ++idx)
    {
		switch(idx)
        {
            case CreditCardTypeVisa:
                reg = visaCardTypeRegex;
                break;
            case CreditCardTypeMasterCard:
                reg = mastercardCardTypeRegex;
                break;
            case CreditCardTypeAMEX:
                reg = amexCardTypeRegex;
                break;
            case CreditCardTypeDiscover:
                reg = discoverCardTypeRegex;
                break;
            case CreditCardTypeDinersClub:
                reg = dinersClubCardTypeRegex;
                break;
		}
		NSUInteger matches = [reg numberOfMatchesInString:proposedNumber options:0 range:NSMakeRange(0, CC_MIN_LENGTH_TO_DETERMINE_CCTYPE)];
		if(matches == 1) return idx;
	}
	return CreditCardTypeInvalid;
}

// http://www.regular-expressions.info/creditcard.html
+ (BOOL)isValidNumber:(NSString *)number
{
	NSRegularExpression *regularExpressionToMatch;
	BOOL valid = NO;
    
	switch([CreditCard ccTypeWithCardNumber:number])
    {
        case CreditCardTypeVisa:
            regularExpressionToMatch = visaValidityRegex;
            break;
        case CreditCardTypeMasterCard:
            regularExpressionToMatch = mastercardValidityRegex;
            break;
        case CreditCardTypeAMEX:
            regularExpressionToMatch = amexValidityRegex;
            break;
        case CreditCardTypeDiscover:
            regularExpressionToMatch = discoverValidityRegex;
            break;
        case CreditCardTypeDinersClub:
            regularExpressionToMatch = dinersClubValidityRegex;
            break;
        default:
            break;
	}
	if(regularExpressionToMatch)
    {
		NSUInteger matches = [regularExpressionToMatch numberOfMatchesInString:number options:0 range:NSMakeRange(0, [number length])];
		valid = matches == 1 ? YES : NO;
        
        if(valid)
        {
            valid = [CreditCard isLuhnValid:number];
        }        
	}
    
	return valid;
}

// See: http://www.brainjar.com/js/validation/default2.asp
+ (BOOL)isLuhnValid:(NSString *)number
{
	NSString *baseNumber = [number stringByReplacingOccurrencesOfString:@" " withString:@""];
	NSUInteger total = 0;
	
	NSUInteger len = [baseNumber length];
	for(NSUInteger i=len; i > 0; ) {
		BOOL odd = (len-i)&1;
		--i;
		unichar c = [baseNumber characterAtIndex:i];
		if(c < '0' || c > '9') continue;
		c -= '0';
		if(odd) c *= 2;
		if(c >= 10) {
			total += 1;
			c -= 10;
		}
		total += c;
	}
	return (total%10) == 0 ? YES : NO;
}


+ (NSString *)formattedStringForCardNumber:(NSString *)enteredNumber
{
	NSString *cleaned = [CreditCard cleanNumber:enteredNumber];
	NSInteger len = [cleaned length];
	
	if(len <= CC_MIN_LENGTH_TO_DETERMINE_CCTYPE) return cleaned;
    
	NSRange r2; r2.location = NSNotFound;
	NSRange r3; r3.location = NSNotFound;
	NSRange r4; r4.location = NSNotFound;
	NSMutableArray *gaps = [NSMutableArray arrayWithObjects:@"", @"", @"", nil];
    
	NSUInteger segmentLengths[3] = { 0, 0, 0 };
    
	switch([CreditCard ccTypeWithCardNumber:enteredNumber]) {
        case CreditCardTypeVisa:
        case CreditCardTypeMasterCard:
        case CreditCardTypeDiscover:		// { 4-4-4-4}
            segmentLengths[0] = 4;
            segmentLengths[1] = 4;
            segmentLengths[2] = 4;
            break;
        case CreditCardTypeAMEX:			// {4-6-5}
            segmentLengths[0] = 6;
            segmentLengths[1] = 5;
            break;
        case CreditCardTypeDinersClub:	// {4-6-4}
            segmentLengths[0] = 6;
            segmentLengths[1] = 4;
            break;
        default:
            return enteredNumber;
	}
    
	len -= CC_MIN_LENGTH_TO_DETERMINE_CCTYPE;
	NSRange *r[3] = { &r2, &r3, &r4 };
	NSUInteger totalLen = CC_MIN_LENGTH_TO_DETERMINE_CCTYPE;
	for(NSUInteger idx=0; idx<3; ++idx) {
		NSInteger segLen = segmentLengths[idx];
		if(!segLen) break;
        
		r[idx]->location = totalLen;
		r[idx]->length = len >= segLen ? segLen : len;
		totalLen += segLen;
		len -= segLen;
		[gaps replaceObjectAtIndex:idx withObject:@" "];
		
		if(len <= 0) break;
	}
	//NSLog(@"Ranges: %@ %@ %@", NSStringFromRange(r2), NSStringFromRange(r3), NSStringFromRange(r4) );
    
	NSString *segment1 = [enteredNumber substringWithRange:NSMakeRange(0, CC_MIN_LENGTH_TO_DETERMINE_CCTYPE)];
	NSString *segment2 = r2.location == NSNotFound ? @"" : [enteredNumber substringWithRange:r2];
	NSString *segment3 = r3.location == NSNotFound ? @"" : [enteredNumber substringWithRange:r3];
	NSString *segment4 = r4.location == NSNotFound ? @"" : [enteredNumber substringWithRange:r4];
    
	NSString *ret = [NSString stringWithFormat:@"%@%@%@%@%@%@%@",
                     segment1, [gaps objectAtIndex:0],
                     segment2, [gaps objectAtIndex:1],
                     segment3, [gaps objectAtIndex:2],
                     segment4 ];
    
	return ret;
}

+ (NSUInteger)lengthOfStringForType:(CreditCardType)type
{
	NSUInteger idx;
	
	switch(type) {
        case CreditCardTypeVisa:
        case CreditCardTypeMasterCard:
        case CreditCardTypeDiscover:		// { 4-4-4-4}
            idx = 16;
            break;
        case CreditCardTypeAMEX:			// {4-6-5}
            idx = 15;
            break;
        case CreditCardTypeDinersClub:	// {4-6-4}
            idx = 14;
            break;
        default:
            idx = 0;
	}
	return idx;
}

+ (NSUInteger)lengthOfFormattedStringForType:(CreditCardType)type
{
	NSUInteger length;
	switch(type) {
        case CreditCardTypeVisa:
        case CreditCardTypeMasterCard:
        case CreditCardTypeDiscover:		// { 4-4-4-4}
            length = 16 + 3;
            break;
        case CreditCardTypeAMEX:			// {4-6-5}
            length = 15 + 2;
            break;
        case CreditCardTypeDinersClub:	// {4-6-4}
            length = 14 + 2;
            break;
        default:
            length = 0;
	}
	return length;
}

+ (NSUInteger)lengthOfFormattedStringTillLastGroupForType:(CreditCardType)type
{
	NSUInteger length;
	switch(type) {
        case CreditCardTypeVisa:
        case CreditCardTypeMasterCard:
        case CreditCardTypeDiscover:		// { 4-4-4-4}
            length = 16 + 3 - 4;
            break;
        case CreditCardTypeAMEX:			// {4-6-5}
            length = 15 + 2 - 5;
            break;
        case CreditCardTypeDinersClub:	// {4-6-4}
            length = 14 + 2 - 4;
            break;
        default:
            length = 0;
	}
	return length;
}

+ (NSString *)ccvFormat:(CreditCardType)type
{
	return type == CreditCardTypeAMEX ? @"%04.4u" : @"%03.3u";
}

+ (NSString *)promptStringForType:(CreditCardType)type justNumber:(BOOL)justNumber
{
	NSString *number;
	NSString *additions;
    
	switch(type) {
        case CreditCardTypeVisa:
        case CreditCardTypeMasterCard:
        case CreditCardTypeDiscover:		// { 4-4-4-4}
            number = @"XXXX XXXX XXXX XXXX";
            additions = @" MM/YY CCV";
            break;
        case CreditCardTypeAMEX:			// {4-6-5}
            number = @"XXXX XXXXXX XXXXX";
            additions = @" MM/YY CIDV";
            break;
        case CreditCardTypeDinersClub:	// {4-6-4}
            number = @"XXXX XXXXXX XXXX";
            additions = @" MM/YY CCV";
            break;
        default:
            break;
	}
	return justNumber ? number : [number stringByAppendingString:additions];
}
+ (NSString *)obscuredCardWithNumber:(NSString *)cardNumber
{
    CreditCardType type = [CreditCard ccTypeWithCardNumber:cardNumber];
    NSString *formattedCardNumber = [CreditCard formattedStringForCardNumber:cardNumber];
    NSString *obscuredPortion_unobscured = [formattedCardNumber substringToIndex:[CreditCard lengthOfFormattedStringTillLastGroupForType:type]];
    NSScanner *scanner = [NSScanner scannerWithString:obscuredPortion_unobscured];
    NSMutableString *obscuredPortion = [NSMutableString stringWithCapacity:obscuredPortion_unobscured.length];
    NSCharacterSet *numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    while ([scanner isAtEnd] == NO) {
        NSString *buffer;
        if ([scanner scanCharactersFromSet:numbers intoString:&buffer]) {
            for(NSUInteger i=0;i<buffer.length;i++)
            {
                [obscuredPortion appendString:@"•"];
            }
            [obscuredPortion appendString:@" "];
        } else {            
            [scanner setScanLocation:([scanner scanLocation] + 1)];
        }
    }
    [obscuredPortion appendString:[formattedCardNumber substringFromIndex:[CreditCard lengthOfFormattedStringTillLastGroupForType:type]]];
    return [NSString stringWithFormat:@"%@ %@",[CreditCard cardTypeNameForType:type],obscuredPortion];
}
+ (NSString *) cardTypeNameForType:(CreditCardType)type
{
    if(type==CreditCardTypeVisa)
    {
        return CardTypeNameVisa;
    }else if(type==CreditCardTypeMasterCard)
    {
        return CardTypeNameMasterCard;
    }else if(type==CreditCardTypeDiscover)
    {
        return CardTypeNameDiscover;
    }
    else if(type==CreditCardTypeAMEX)
    {
        return CardTypeNameAmex;
    }else if(type==CreditCardTypeDinersClub)
    {
        return CardTypeNameDinersClub;
    }else
    {
        return nil;
    }
}

@end
