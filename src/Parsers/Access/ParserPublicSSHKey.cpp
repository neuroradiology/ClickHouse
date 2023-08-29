#include <Parsers/Access/ParserPublicSSHKey.h>
#include <Parsers/Access/ASTPublicSSHKey.h>

#include <Parsers/CommonParsers.h>
#include <Parsers/parseIdentifierOrStringLiteral.h>
#include <boost/algorithm/string.hpp>


namespace DB
{

namespace
{
    bool parsePublicSSHKey(IParserBase::Pos & pos, Expected & expected, std::shared_ptr<ASTPublicSSHKey> & ast)
    {
        return IParserBase::wrapParseImpl(pos, [&]
        {
            String key_base64;
            if (!ParserKeyword{"KEY"}.ignore(pos, expected) || !parseIdentifierOrStringLiteral(pos, expected, key_base64))
                return false;

            String algorithm;
            if (!ParserKeyword{"ALGORITHM"}.ignore(pos, expected) || !parseIdentifierOrStringLiteral(pos, expected, algorithm))
                return false;

            ast = std::make_shared<ASTPublicSSHKey>();
            ast->key_base64 = std::move(key_base64);
            ast->algorithm = std::move(algorithm);
            return true;
        });
    }
}


bool ParserPublicSSHKey::parseImpl(Pos & pos, ASTPtr & node, Expected & expected)
{
    std::shared_ptr<ASTPublicSSHKey> res;
    if (!parsePublicSSHKey(pos, expected, res))
        return false;

    node = res;
    return true;
}

}
